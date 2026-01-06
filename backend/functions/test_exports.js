const modules = [
  "./lib/chat_service.js",
  "./lib/user_handler.js", 
  "./lib/post_handler.js",
  "./lib/report_handler.js"
];

modules.forEach(mod => {
  try {
    const exports = require(mod);
    console.log(`✅ ${mod}: 导出 ${Object.keys(exports).length} 个函数`);
  } catch (err) {
    console.error(`❌ ${mod}: ${err.message}`);
  }
});
