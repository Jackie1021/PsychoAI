try {
  console.log("测试导入...");
  const functions = require("firebase-functions");
  console.log("✅ firebase-functions 导入成功");
  
  const admin = require("firebase-admin");
  console.log("✅ firebase-admin 导入成功");
  
  const lib = require("./lib/index.js");
  console.log("✅ index.js 导入成功");
  console.log("导出函数：", Object.keys(lib).slice(0, 5), "...");
} catch (error) {
  console.error("❌ 导入失败：", error.message);
  console.error(error.stack);
  process.exit(1);
}
