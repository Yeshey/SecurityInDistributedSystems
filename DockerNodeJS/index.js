const express = require('express')
const app = express()
app.get('/', ( req, res ) => {
    //res.sendFile(`${__dirname}/index.html`)

    let name = JSON.stringify(req.header('ssl_client_s_dn')).split(',')[0].split("CN=")[1]

    res.send("<html>" + 
        "<body>" +
        "<h1>" +
        "Welcome " + name + 
        "</h1>" +
        "<br><br><br>More information:<br>" + JSON.stringify(req.headers)) +
        "</body>" +
        "</html>";
})
app.listen(3000, () => {
    console.log('Listening on port 3000!')
})