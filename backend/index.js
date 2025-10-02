const express = require('express');
const app = express();
app.use(express.json());

app.get('/api/health', (req, res) => res.json({ ok: true }));
app.get('/api/hello', (req, res) => res.json({ msg: 'Hello from backend' }));

app.listen(process.env.PORT || 3000, () => {
  console.log('Backend listening on', process.env.PORT || 3000);
});
