import 'dart:async';
import 'dart:math';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/clay_kit.dart';
import '../data/live_repository.dart';
import '../domain/live_session.dart';

class LiveRoomScreen extends ConsumerStatefulWidget {
  const LiveRoomScreen({super.key, required this.session});

  final LiveSession session;

  @override
  ConsumerState<LiveRoomScreen> createState() => _LiveRoomScreenState();
}

class _LiveRoomScreenState extends ConsumerState<LiveRoomScreen> {
  late final LiveRepository _repo;
  RtcEngine? _engine;
  LivePass? _pass;
  bool _joined = false;
  bool _ended = false;
  String? _error;

  final List<int> _broadcasters = [];
  final Map<int, String> _accounts = {};

  String? _stageStatus;
  bool _onStage = false;
  bool _switching = false;
  bool _micOn = true;
  bool _camOn = true;

  bool _expanded = false;
  bool _alertDismissed = false;
  final GlobalKey<_HeartBurstState> _hearts = GlobalKey();

  StreamSubscription<LiveStatus>? _statusSub;
  StreamSubscription<String?>? _stageSub;

  @override
  void initState() {
    super.initState();
    _repo = ref.read(liveRepositoryProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) => _join());
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    _stageSub?.cancel();
    if (_stageStatus == 'pending' || _stageStatus == 'approved') {
      _repo.leaveStage(widget.session.id).catchError((_) {});
    }
    final engine = _engine;
    if (engine != null) {
      engine.leaveChannel().whenComplete(engine.release).catchError((_) {});
    }
    super.dispose();
  }

  Future<void> _join() async {
    try {
      final pass = await _repo.fetchPass(widget.session.id);
      final engine = createAgoraRtcEngine();
      await engine.initialize(RtcEngineContext(
        appId: pass.appId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));
      engine.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (_, __) {
          if (mounted) setState(() => _joined = true);
        },
        onUserJoined: (_, uid, __) {
          if (!mounted) return;
          setState(() {
            if (!_broadcasters.contains(uid)) _broadcasters.add(uid);
          });
          _resolveAccount(uid);
        },
        onUserOffline: (_, uid, __) {
          if (mounted) setState(() => _broadcasters.remove(uid));
        },
        onUserInfoUpdated: (uid, info) {
          final account = info.userAccount;
          if (account != null && mounted) setState(() => _accounts[uid] = account);
        },
        onTokenPrivilegeWillExpire: (_, __) => _renewToken(),
        onError: (err, msg) {
          if (kDebugMode) debugPrint('[Live] agora error $err $msg');
        },
      ));
      await engine.enableVideo();
      await engine.setClientRole(
        role: ClientRoleType.clientRoleAudience,
        options: const ClientRoleOptions(
          audienceLatencyLevel: AudienceLatencyLevelType.audienceLatencyLevelLowLatency,
        ),
      );
      await engine.joinChannelWithUserAccount(
        token: pass.token ?? '',
        channelId: pass.channel,
        userAccount: pass.account,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleAudience,
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
        ),
      );
      if (!mounted) {
        await engine.leaveChannel();
        await engine.release();
        return;
      }
      setState(() {
        _engine = engine;
        _pass = pass;
      });
      _statusSub = _repo.watchStatus(widget.session.id).listen((status) {
        if (status == LiveStatus.ended && mounted && !_ended) _onEnded();
      });
      _stageSub = _repo.watchMyStageStatus(widget.session.id).listen(_onStageStatus);
    } on LiveException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (kDebugMode) debugPrint('[Live] join failed: $e');
      if (mounted) setState(() => _error = 'تعذّر الدخول للايف، تأكدي من الإنترنت وحاولي تاني');
    }
  }

  Future<void> _resolveAccount(int uid) async {
    try {
      final info = await _engine?.getUserInfoByUid(uid);
      final account = info?.userAccount;
      if (account != null && mounted) setState(() => _accounts[uid] = account);
    } catch (_) {}
  }

  Future<void> _renewToken() async {
    try {
      final pass = await _repo.fetchPass(widget.session.id);
      final token = pass.token;
      if (token != null) await _engine?.renewToken(token);
      _pass = pass;
    } catch (_) {}
  }

  void _onEnded() {
    setState(() => _ended = true);
    final engine = _engine;
    _engine = null;
    if (engine != null) engine.leaveChannel().whenComplete(engine.release).catchError((_) {});
  }

  Future<void> _onStageStatus(String? status) async {
    if (!mounted) return;
    setState(() {
      _stageStatus = status;
      _alertDismissed = false;
    });
    if (status == 'approved' && !_onStage) {
      await _goOnStage();
    } else if (status != 'approved' && _onStage) {
      await _dropToAudience();
      if (mounted && status == 'left') _snack('المدرّبة نزّلتك من المسرح');
    } else if (status == 'rejected') {
      _snack('المدرّبة مش هتقدر تطلّعك دلوقتي');
    }
  }

  Future<void> _goOnStage() async {
    final engine = _engine;
    if (engine == null || _switching) return;
    setState(() => _switching = true);
    try {
      final results = await [Permission.camera, Permission.microphone].request();
      if (results.values.any((s) => !s.isGranted)) {
        _snack('لازم تسمحي بالكاميرا والمايك علشان تطلعي على المسرح');
        await _repo.leaveStage(widget.session.id);
        return;
      }
      final pass = await _repo.fetchPass(widget.session.id);
      final token = pass.token;
      if (token != null) await engine.renewToken(token);
      _pass = pass;
      await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      await engine.updateChannelMediaOptions(const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
      ));
      await engine.startPreview();
      if (mounted) {
        setState(() {
          _onStage = true;
          _micOn = true;
          _camOn = true;
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Live] go on stage failed: $e');
      _snack('تعذّر الطلوع على المسرح');
    } finally {
      if (mounted) setState(() => _switching = false);
    }
  }

  Future<void> _dropToAudience() async {
    final engine = _engine;
    if (engine == null) return;
    try {
      await engine.updateChannelMediaOptions(const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleAudience,
        publishCameraTrack: false,
        publishMicrophoneTrack: false,
      ));
      await engine.setClientRole(
        role: ClientRoleType.clientRoleAudience,
        options: const ClientRoleOptions(
          audienceLatencyLevel: AudienceLatencyLevelType.audienceLatencyLevelLowLatency,
        ),
      );
      await engine.stopPreview();
    } catch (_) {}
    if (mounted) setState(() => _onStage = false);
  }

  Future<void> _raiseHand() async {
    try {
      await _repo.raiseHand(widget.session.id);
    } catch (e) {
      if (kDebugMode) debugPrint('[Live] raise hand failed: $e');
      _snack('تعذّر رفع الإيد، حاولي تاني');
    }
  }

  Future<void> _leaveStage() async {
    await _repo.leaveStage(widget.session.id).catchError((_) {});
  }

  Future<void> _toggleMic() async {
    if (!_onStage) {
      _snack('ارفعي إيدك الأول، ولما المدرّبة تطلّعك المايك هيشتغل');
      return;
    }
    await _engine?.muteLocalAudioStream(_micOn);
    setState(() => _micOn = !_micOn);
  }

  Future<void> _toggleCam() async {
    if (!_onStage) {
      _snack('ارفعي إيدك الأول، ولما المدرّبة تطلّعك الكاميرا هتشتغل');
      return;
    }
    await _engine?.muteLocalVideoStream(_camOn);
    setState(() => _camOn = !_camOn);
  }

  void _onHandTap() {
    if (_onStage || _stageStatus == 'pending') {
      _leaveStage();
    } else if (!_switching) {
      _raiseHand();
    }
  }

  void _showAbout() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(kClayRadiusLg))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.session.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.onSurface),
            ),
            const SizedBox(height: 12),
            Text(
              widget.session.description,
              style: const TextStyle(fontSize: 15, height: 1.7, color: AppColors.onSurface),
            ),
          ],
        ),
      ),
    );
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  int? get _hostUid {
    for (final uid in _broadcasters) {
      if (_accounts[uid]?.startsWith('host_') ?? false) return uid;
    }
    return _broadcasters.isEmpty ? null : _broadcasters.first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const ClayHeader(title: 'قاعة اللايف'),
      body: Stack(
        children: [
          _buildBody(),
          Positioned.fill(child: IgnorePointer(child: _HeartBurst(key: _hearts))),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null) return _Message(icon: Symbols.error, text: _error!);
    if (_ended) return const _Message(icon: Symbols.check_circle, text: 'اللايف انتهى، شكراً لحضورك 🌸');
    final engine = _engine;
    final pass = _pass;
    if (engine == null || pass == null) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    final stage = _buildStage(engine, RtcConnection(channelId: pass.channel));
    if (_expanded) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          children: [
            _buildStatusCard(),
            const SizedBox(height: 16),
            Expanded(child: stage),
            const SizedBox(height: 16),
            _buildDock(),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _buildStatusCard(),
        const SizedBox(height: 16),
        SizedBox(height: 400, child: stage),
        const SizedBox(height: 16),
        _buildTopicBanner(),
        const SizedBox(height: 16),
        _buildDock(),
      ],
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: clayDecoration(lift: 0.8),
      child: Row(
        children: [
          ClayPill(
            leading: const ClayPulseDot(),
            text: _joined ? 'مباشر الآن 🔴' : 'بيتصل…',
            background: AppColors.errorContainer,
            foreground: AppColors.onErrorContainer,
          ),
          const SizedBox(width: 8),
          if (_broadcasters.length > 1)
            ClayPill(
              icon: Symbols.groups,
              text: '${_broadcasters.length - 1} على المسرح',
              background: AppColors.surfaceContainerHigh,
              foreground: AppColors.onSurface,
              iconColor: AppColors.primary,
            ),
          const Spacer(),
          Material(
            color: AppColors.surfaceContainer,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => setState(() => _expanded = !_expanded),
              child: SizedBox.square(
                dimension: 36,
                child: Icon(
                  _expanded ? Symbols.fullscreen_exit : Symbols.fullscreen,
                  size: 20,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStage(RtcEngine engine, RtcConnection connection) {
    final session = widget.session;
    final hostUid = _hostUid;
    final others = _broadcasters.where((uid) => uid != hostUid).toList();
    final showAlert = !_alertDismissed && (_onStage || _stageStatus == 'pending');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.onSurface,
        borderRadius: BorderRadius.circular(kClayRadiusXl),
        boxShadow: [
          BoxShadow(color: AppColors.onSurface.withValues(alpha: 0.18), blurRadius: 48, offset: const Offset(0, 20)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          hostUid == null
              ? const _Message(icon: Symbols.hourglass_top, text: 'في انتظار المدرّبة…', light: true)
              : AgoraVideoView(
                  controller: VideoViewController.remote(
                    rtcEngine: engine,
                    canvas: VideoCanvas(uid: hostUid),
                    connection: connection,
                  ),
                ),
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xE6493732), Color(0x33493732), Color(0x66493732)],
                ),
              ),
            ),
          ),
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_onStage || others.isNotEmpty)
                  Column(
                    children: [
                      if (_onStage)
                        _Pip(
                          label: 'أنتِ وصغيرك 👶',
                          muted: !_micOn,
                          onSwitchCamera: () => _engine?.switchCamera(),
                          child: AgoraVideoView(
                            controller: VideoViewController(rtcEngine: engine, canvas: const VideoCanvas(uid: 0)),
                          ),
                        ),
                      for (final uid in others)
                        _Pip(
                          label: 'أم على المسرح',
                          child: AgoraVideoView(
                            controller: VideoViewController.remote(
                              rtcEngine: engine,
                              canvas: VideoCanvas(uid: uid),
                              connection: connection,
                            ),
                          ),
                        ),
                    ],
                  ),
                const Spacer(),
                if (session.instructorName.isNotEmpty)
                  Flexible(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(color: AppColors.secondaryFixedDim, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              session.instructorName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.onSurface),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (showAlert)
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: _StageAlert(
                onStage: _onStage,
                onClose: () => setState(() => _alertDismissed = true),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopicBanner() {
    final session = widget.session;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: clayDecoration(lift: 0.6),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryFixedDim,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 1.5),
              boxShadow: [
                BoxShadow(color: AppColors.primary.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: const Icon(Symbols.live_tv, color: AppColors.onPrimaryContainer, size: 28, fill: 1),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'موضوع اللايف',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
                Text(
                  session.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 18, height: 1.3, fontWeight: FontWeight.w800, color: AppColors.onSurface),
                ),
              ],
            ),
          ),
          if (session.description.isNotEmpty) ...[
            const SizedBox(width: 8),
            Material(
              color: kClayAccentLight,
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: _showAbout,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Text(
                    'عن اللايف',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.onSurface),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDock() {
    final handActive = _onStage || _stageStatus == 'pending';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      decoration: clayDecoration(color: AppColors.surfaceContainerHigh, radius: kClayRadiusXl, lift: 0.5),
      child: Row(
        children: [
          Expanded(
            child: _DockButton(
              icon: _onStage && !_micOn ? Symbols.mic_off : Symbols.mic,
              label: !_onStage ? 'المايك' : _micOn ? 'صوتكِ نشط' : 'المايك مقفول',
              bg: _onStage && _micOn ? AppColors.primary : Colors.white,
              fg: _onStage && _micOn ? Colors.white : AppColors.onSurface,
              labelColor: _onStage && _micOn ? AppColors.onSurface : AppColors.onSurfaceVariant,
              onTap: _toggleMic,
            ),
          ),
          Expanded(
            child: _DockButton(
              icon: _onStage && !_camOn ? Symbols.videocam_off : Symbols.videocam,
              label: 'الكاميرا',
              bg: Colors.white,
              fg: AppColors.onSurface,
              labelColor: AppColors.onSurfaceVariant,
              onTap: _toggleCam,
            ),
          ),
          Expanded(
            child: _DockButton(
              icon: Symbols.back_hand,
              label: _onStage ? 'انزلي' : handActive ? 'اليد مرفوعة' : 'ارفعي إيدك',
              bg: handActive ? AppColors.secondary : AppColors.secondaryFixedDim,
              fg: handActive ? Colors.white : AppColors.onSecondaryContainer,
              labelColor: AppColors.secondaryDim,
              onTap: _onHandTap,
            ),
          ),
          Expanded(
            child: _DockButton(
              icon: Symbols.favorite,
              label: 'تشجيع',
              bg: kClayAccentLight,
              fg: kClayAccent,
              labelColor: kClayAccent,
              onTap: () => _hearts.currentState?.burst(),
            ),
          ),
          Expanded(
            child: _DockButton(
              icon: Symbols.call_end,
              label: 'مغادرة',
              bg: AppColors.errorContainer,
              fg: AppColors.onErrorContainer,
              labelColor: AppColors.error,
              onTap: () => Navigator.of(context).maybePop(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pip extends StatelessWidget {
  const _Pip({required this.label, required this.child, this.muted = false, this.onSwitchCamera});

  final String label;
  final Widget child;
  final bool muted;
  final VoidCallback? onSwitchCamera;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      height: 140,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(kClayRadiusLg),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 25, offset: const Offset(0, 10)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          child,
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.center,
                  colors: [Color(0xB3493732), Color(0x00493732)],
                ),
              ),
            ),
          ),
          PositionedDirectional(
            top: 6,
            start: 6,
            child: Row(
              children: [
                if (onSwitchCamera != null)
                  GestureDetector(
                    onTap: onSwitchCamera,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Symbols.cameraswitch, size: 14, color: AppColors.primary),
                    ),
                  ),
                if (muted) ...[
                  const SizedBox(width: 4),
                  Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                    child: const Icon(Symbols.mic_off, size: 14, color: Colors.white),
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            left: 6,
            right: 6,
            bottom: 6,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _StageAlert extends StatelessWidget {
  const _StageAlert({required this.onStage, required this.onClose});

  final bool onStage;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.secondaryFixedDim,
        borderRadius: BorderRadius.circular(kClayRadiusLg),
        border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 1.5),
        boxShadow: [
          BoxShadow(color: AppColors.secondaryDim.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Icon(onStage ? Symbols.mic : Symbols.back_hand, size: 20, color: AppColors.secondary, fill: 1),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              onStage
                  ? 'المدرّبة منحتكِ المايك للتحدث! صوتكِ مسموع للجميع الآن 🎙️'
                  : 'رفعتي إيدك ✋ استني المدرّبة تطلّعك',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.onSecondaryContainer),
            ),
          ),
          GestureDetector(
            onTap: onClose,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Symbols.close, size: 18, color: AppColors.onSecondaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _DockButton extends StatelessWidget {
  const _DockButton({
    required this.icon,
    required this.label,
    required this.bg,
    required this.fg,
    required this.labelColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;
  final Color labelColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: bg,
          borderRadius: BorderRadius.circular(kClayRadiusLg / 2),
          elevation: 3,
          shadowColor: bg.withValues(alpha: 0.6),
          child: InkWell(
            borderRadius: BorderRadius.circular(kClayRadiusLg / 2),
            onTap: onTap,
            child: SizedBox.square(
              dimension: 48,
              child: Icon(icon, color: fg, fill: 1),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: labelColor),
        ),
      ],
    );
  }
}

/// Floating hearts that rise from the encouragement button.
class _HeartBurst extends StatefulWidget {
  const _HeartBurst({super.key});

  @override
  State<_HeartBurst> createState() => _HeartBurstState();
}

class _HeartBurstState extends State<_HeartBurst> {
  final _random = Random();
  final List<_Heart> _items = [];
  int _nextId = 0;

  void burst() {
    setState(() {
      for (var i = 0; i < 6; i++) {
        _items.add(_Heart(
          id: _nextId++,
          dx: (_random.nextDouble() - 0.5) * 80,
          rise: 140 + _random.nextDouble() * 100,
          size: 22 + _random.nextDouble() * 14,
        ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final originX = box.maxWidth * 0.35;
        final originY = box.maxHeight - 140;
        return Stack(
          children: [
            for (final h in _items)
              TweenAnimationBuilder<double>(
                key: ValueKey(h.id),
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOutCubic,
                onEnd: () => setState(() => _items.remove(h)),
                builder: (_, t, child) => Positioned(
                  left: originX + h.dx * t,
                  top: originY - h.rise * t,
                  child: Opacity(
                    opacity: 1 - t,
                    child: Transform.scale(scale: 1 + 0.4 * t, child: child),
                  ),
                ),
                child: Text('💖', style: TextStyle(fontSize: h.size)),
              ),
          ],
        );
      },
    );
  }
}

class _Heart {
  _Heart({required this.id, required this.dx, required this.rise, required this.size});

  final int id;
  final double dx;
  final double rise;
  final double size;
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.light = false});

  final IconData icon;
  final String text;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: light ? Colors.white70 : AppColors.primary, size: 48),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(color: light ? Colors.white : AppColors.onSurface, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
