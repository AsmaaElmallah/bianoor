-- إيصال المتجر الواحد يفتح دورة لحساب واحد بس.
create unique index if not exists course_enrollments_store_receipt_idx
  on public.course_enrollments (store_receipt)
  where store_receipt is not null;
