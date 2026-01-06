console.log("Testing Cloud Functions compilation...");
try {
  const functions = require("firebase-functions");
  const admin = require("firebase-admin");
  const index = require("./lib/index.js");
  
  const exportedFuncs = Object.keys(index);
  console.log("✅ Successfully compiled!");
  console.log("✅ Exported functions:", exportedFuncs.slice(0, 5).join(", "), "...");
  console.log("✅ Ready to deploy!");
  process.exit(0);
} catch (error) {
  console.error("❌ Error:", error.message);
  process.exit(1);
}
