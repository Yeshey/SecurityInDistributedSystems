const express = require('express')
const app = express()
app.get('/', ( req, res ) => {
    //res.sendFile(`${__dirname}/index.html`)

    console.log("please1")

    res.send("Oh yeah\n" + JSON.stringify(req.headers));
})
app.listen(3000, () => {
    console.log('Listening on port 3000!')
})
console.log("please2")