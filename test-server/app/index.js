const express = require('express')
const app = express()

app.get('/data', (req, res) => {
  return res.status(200).json({
    data: 'hello world'
  })
})

app.listen(8080, (err) => {
  if (err) {
    console.error(err)
    process.exit(1)
  }
  console.log('Server has started at port 8080')
})

