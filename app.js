var connect = require('connect');
var serveStatic = require('serve-static');

connect()
    .use(serveStatic(__dirname + '/site'))
    .listen(3000, () => console.log('Server running on port 3000...'));
