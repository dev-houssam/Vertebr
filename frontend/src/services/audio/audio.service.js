// VERTEBR — services/audio/audio.service.js
import { vertebrClient } from '@/services/api/vertebr-client';

class AudioService {
  async listSinks()                        { return vertebrClient.call('audio:sinks'); }
  async listSources()                      { return vertebrClient.call('audio:sources'); }
  async setVolume(name, volume, isSink)    { return vertebrClient.call('audio:volume',  { [isSink ? 'sink' : 'source']: name, volume }); }
  async setMute(name, muted, isSink)       { return vertebrClient.call('audio:mute',    { [isSink ? 'sink' : 'source']: name, muted }); }
  async setDefaultSink(name)              { return vertebrClient.call('audio:default', { name }); }
}
export const audioService = new AudioService();
