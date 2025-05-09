const express = require('express');
const app = express();

app.get('/', (req, res) => {
  console.log('Hello from Node.js app!');
  res.send('Hello from Node.js app!');
});

app.listen(3000, () => {
  console.log('Node.js app listening on port 3000');
});
