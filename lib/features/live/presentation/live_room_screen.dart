import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/theme/app_colors.dart';
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
    setState(() => _stageStatus = status);
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
        _snack('إنتي على المسرح دلوقتي 🎤');
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
      _snack('رفعتي إيدك ✋ استني المدرّبة تطلّعك');
    } catch (e) {
      if (kDebugMode) debugPrint('[Live] raise hand failed: $e');
      _snack('تعذّر رفع الإيد، حاولي تاني');
    }
  }

  Future<void> _leaveStage() async {
    await _repo.leaveStage(widget.session.id).catchError((_) {});
  }

  Future<void> _toggleMic() async {
    await _engine?.muteLocalAudioStream(_micOn);
    setState(() => _micOn = !_micOn);
  }

  Future<void> _toggleCam() async {
    await _engine?.muteLocalVideoStream(_camOn);
    setState(() => _camOn = !_camOn);
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
      backgroundColor: const Color(0xFF15121F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(widget.session.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          if (_joined && !_ended)
            Container(
              margin: const EdgeInsetsDirectional.only(end: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(20)),
              child: const Text('مباشر', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_error != null) return _Message(icon: Symbols.error, text: _error!);
    if (_ended) return const _Message(icon: Symbols.check_circle, text: 'اللايف انتهى، شكراً لحضورك 🌸');
    final engine = _engine;
    final pass = _pass;
    if (engine == null || pass == null) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    final hostUid = _hostUid;
    final others = _broadcasters.where((uid) => uid != hostUid).toList();
    final connection = RtcConnection(channelId: pass.channel);

    return Column(
      children: [
        Expanded(
          child: hostUid == null
              ? const _Message(icon: Symbols.hourglass_top, text: 'في انتظار المدرّبة…')
              : AgoraVideoView(
                  controller: VideoViewController.remote(
                    rtcEngine: engine,
                    canvas: VideoCanvas(uid: hostUid),
                    connection: connection,
                  ),
                ),
        ),
        if (others.isNotEmpty || _onStage)
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(8),
              children: [
                if (_onStage)
                  _StageTile(
                    label: 'إنتي',
                    child: AgoraVideoView(
                      controller: VideoViewController(rtcEngine: engine, canvas: const VideoCanvas(uid: 0)),
                    ),
                  ),
                for (final uid in others)
                  _StageTile(
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
          ),
        _buildControls(),
      ],
    );
  }

  Widget _buildControls() {
    final List<Widget> buttons;
    if (_onStage) {
      buttons = [
        _RoundButton(
          icon: _micOn ? Symbols.mic : Symbols.mic_off,
          label: _micOn ? 'كتم' : 'تشغيل',
          onTap: _toggleMic,
        ),
        _RoundButton(
          icon: _camOn ? Symbols.videocam : Symbols.videocam_off,
          label: _camOn ? 'الكاميرا' : 'تشغيل',
          onTap: _toggleCam,
        ),
        _RoundButton(icon: Symbols.cameraswitch, label: 'قلب', onTap: () => _engine?.switchCamera()),
        _RoundButton(icon: Symbols.logout, label: 'انزلي', color: Colors.red, onTap: _leaveStage),
      ];
    } else if (_stageStatus == 'pending') {
      buttons = [
        _RoundButton(icon: Symbols.front_hand, label: 'إلغاء رفع الإيد', color: Colors.amber, onTap: _leaveStage),
      ];
    } else {
      buttons = [
        _RoundButton(
          icon: Symbols.front_hand,
          label: 'ارفعي إيدك',
          onTap: _switching ? null : _raiseHand,
        ),
      ];
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: buttons),
    );
  }
}

class _StageTile extends StatelessWidget {
  const _StageTile({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      margin: const EdgeInsetsDirectional.only(end: 8),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(14)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          child,
          Positioned(
            bottom: 4,
            left: 4,
            right: 4,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 11, shadows: [Shadow(blurRadius: 4)]),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.label, required this.onTap, this.color});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: color ?? AppColors.primary,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Icon(icon, color: Colors.white, fill: 1),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white70, size: 48),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
