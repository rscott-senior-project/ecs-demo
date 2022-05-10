const express = require("express")
const app = express()
const port = process.env.PORT | 8888

app.get('/', (req, res) => {
  res.send("Hello from ECS Fargate")
})

app.listen(port, () => {
  console.log(`ECS application listening on port ${port}`)
})

