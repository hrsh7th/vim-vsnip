process.stdin.resume();
process.stdin.setEncoding('utf8');

var stdin = '';
process.stdin.on('data', function(chunk) {
    stdin += chunk;
});
process.stdin.on('end', function() {
  var args = JSON.parse(stdin);
  var expr = args.expr;
  var ptrn = args.ptrn;
  var repl = args.repl;
  var flag = args.flag;
  process.stdout.write(expr.replace(new RegExp(ptrn, flag), repl));
});

