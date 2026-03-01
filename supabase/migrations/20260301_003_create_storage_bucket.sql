-- Create storage bucket for raw transcript text files
INSERT INTO storage.buckets (id, name, public)
VALUES ('transcripts', 'transcripts', false);

-- Storage policy: allow service role full access to transcript files
CREATE POLICY "Service role can manage transcripts"
  ON storage.objects FOR ALL
  USING (bucket_id = 'transcripts')
  WITH CHECK (bucket_id = 'transcripts');

-- Allow authenticated users to read transcript files
CREATE POLICY "Authenticated users can read transcripts"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'transcripts' AND auth.role() = 'authenticated');
