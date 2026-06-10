// Corpus fixture: YAGNI — config knobs for transports that do not exist. Only
// mode is ever read; grpcEndpoint and kafkaTopic are speculative slots for a
// hypothetical future, which is exactly the construct the rule bans.
export const transportSettings = {
  mode: 'http',
  grpcEndpoint: '', // EXPECT-SEMANTIC: solid.yagni
  kafkaTopic: '',
}

export function send(client, payload) {
  if (transportSettings.mode === 'http') {
    return client.post('/events', payload)
  }
  return null
}
