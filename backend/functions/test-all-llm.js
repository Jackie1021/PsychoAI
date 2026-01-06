#!/usr/bin/env node
/**
 * Comprehensive test script for all LLM services
 * Tests: Match analysis, Match pattern analysis, Yearly analysis
 */

const fetch = require('node-fetch');
require('dotenv').config();

const API_KEY = process.env.GEMINI_API_KEY;
const BASE_URL = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

console.log('🧪 Testing All LLM Services\n');
console.log('=' .repeat(60));

// Check API key
if (!API_KEY) {
  console.error('❌ Error: GEMINI_API_KEY not found in environment');
  console.error('💡 Set it with: export GEMINI_API_KEY="your_key_here"');
  process.exit(1);
}

console.log(`✅ API Key found (length: ${API_KEY.length})`);
console.log('=' .repeat(60));

// Test data
const mockUsers = {
  userA: {
    traits: ['storyteller', 'night owl', 'creative'],
    freeText: 'Loves rainy nights and old books. Dreams in vivid colors.'
  },
  userB: {
    traits: ['listener', 'dreamer', 'creative'],
    freeText: 'Finds magic in quiet moments and whispered stories.'
  }
};

const mockStatistics = {
  totalMatches: 42,
  chattedCount: 15,
  skippedCount: 27,
  avgCompatibility: 0.68,
  maxCompatibility: 0.92,
  totalChatMessages: 234
};

const mockTraitAnalysis = [
  { trait: 'creative', matchCount: 28, avgScore: 85, successRate: 0.7 },
  { trait: 'thoughtful', matchCount: 20, avgScore: 78, successRate: 0.65 },
  { trait: 'adventurous', matchCount: 15, avgScore: 72, successRate: 0.6 }
];

/**
 * Call Gemini API
 */
async function callGemini(prompt) {
  const url = `${BASE_URL}?key=${API_KEY}`;
  
  const requestBody = {
    contents: [{
      parts: [{ text: prompt }]
    }],
    generationConfig: {
      temperature: 0.8,
      topK: 40,
      topP: 0.95,
      maxOutputTokens: 2048,
    }
  };

  const response = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(requestBody)
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`API Error ${response.status}: ${error}`);
  }

  const data = await response.json();
  
  if (!data.candidates || data.candidates.length === 0) {
    throw new Error('No response from API');
  }

  return data.candidates[0].content.parts[0].text;
}

/**
 * Test 1: Match Analysis (for getMatches function)
 */
async function testMatchAnalysis() {
  console.log('\n📊 Test 1: Match Analysis');
  console.log('-'.repeat(60));

  const prompt = `You are a matchmaker analyzing compatibility between two users.

User A Traits: ${mockUsers.userA.traits.join(", ")}
User A Bio: "${mockUsers.userA.freeText}"

User B Traits: ${mockUsers.userB.traits.join(", ")}
User B Bio: "${mockUsers.userB.freeText}"

Respond with a JSON object containing:
1. summary: A witty one-liner about their compatibility (under 15 words)
2. totalScore: A compatibility score from 0-100
3. similarFeatures: An object with 3-4 areas of similarity, each with score and explanation

Return ONLY valid JSON, no other text.`;

  try {
    console.log('📤 Sending request...');
    const response = await callGemini(prompt);
    
    console.log('📥 Raw response:');
    console.log(response.substring(0, 500));
    
    // Parse JSON
    const jsonMatch = response.match(/```json\s*([\s\S]*?)\s*```/);
    const jsonText = jsonMatch ? jsonMatch[1] : response;
    const parsed = JSON.parse(jsonText);
    
    console.log('\n✅ Parsed successfully:');
    console.log(`   Summary: ${parsed.summary}`);
    console.log(`   Total Score: ${parsed.totalScore}`);
    console.log(`   Features: ${Object.keys(parsed.similarFeatures).length}`);
    
    return true;
  } catch (error) {
    console.error('❌ Test failed:', error.message);
    return false;
  }
}

/**
 * Test 2: Match Pattern Analysis
 */
async function testMatchPattern() {
  console.log('\n🔍 Test 2: Match Pattern Analysis');
  console.log('-'.repeat(60));

  const prompt = `你是一位专业的匹配分析师，擅长从用户的匹配数据中发现深层洞察。请分析以下匹配数据并提供个性化的分析报告。

## 用户匹配数据（最近30天）

### 基本统计
- 总匹配数: ${mockStatistics.totalMatches}
- 开始聊天: ${mockStatistics.chattedCount}次
- 跳过: ${mockStatistics.skippedCount}次  
- 平均兼容性: ${(mockStatistics.avgCompatibility * 100).toFixed(1)}%
- 最高兼容性: ${(mockStatistics.maxCompatibility * 100).toFixed(1)}%
- 聊天消息总数: ${mockStatistics.totalChatMessages}

### 特质分析
${mockTraitAnalysis.map(t => 
  `- **${t.trait}**: 匹配${t.matchCount}次，平均分${t.avgScore}，成功率${(t.successRate * 100).toFixed(1)}%`
).join('\n')}

## 请提供分析报告

请用温暖、鼓励但真实的语气，提供一份**300-500字**的个性化分析报告。

直接输出分析文本，不需要JSON格式。`;

  try {
    console.log('📤 Sending request...');
    const response = await callGemini(prompt);
    
    console.log('📥 Response preview:');
    console.log(response.substring(0, 300) + '...');
    console.log(`\n✅ Response length: ${response.length} characters`);
    
    return true;
  } catch (error) {
    console.error('❌ Test failed:', error.message);
    return false;
  }
}

/**
 * Test 3: Yearly Pattern Analysis
 */
async function testYearlyAnalysis() {
  console.log('\n📅 Test 3: Yearly Pattern Analysis');
  console.log('-'.repeat(60));

  const prompt = `你是一位资深的社交行为分析专家。请基于以下数据生成一份全面的年度分析报告。

## 年度数据概览（2024年）

### 匹配统计
- 总匹配数: ${mockStatistics.totalMatches}
- 开始对话: ${mockStatistics.chattedCount}次
- 平均兼容性: ${(mockStatistics.avgCompatibility * 100).toFixed(1)}%

### 关键特质 Top 3
${mockTraitAnalysis.slice(0, 3).map((t, idx) => 
  `${idx + 1}. **${t.trait}**: ${t.matchCount}次匹配，成功率${(t.successRate * 100).toFixed(1)}%`
).join('\n')}

## 请生成 JSON 格式的年度分析报告

\`\`\`json
{
  "overallSummary": "一句话总结（50字以内）",
  "insights": {
    "matchPattern": "匹配模式洞察",
    "communicationStyle": "沟通风格特点",
    "preferences": "核心偏好",
    "growth": "成长轨迹"
  },
  "recommendations": [
    "建议1",
    "建议2",
    "建议3"
  ],
  "personalityTraits": {
    "openness": 0.75,
    "authenticity": 0.85,
    "engagement": 0.70
  },
  "topPreferences": [
    "偏好1",
    "偏好2",
    "偏好3"
  ]
}
\`\`\`

必须返回有效的 JSON。`;

  try {
    console.log('📤 Sending request...');
    const response = await callGemini(prompt);
    
    console.log('📥 Raw response preview:');
    console.log(response.substring(0, 300));
    
    // Parse JSON
    const jsonMatch = response.match(/```json\s*([\s\S]*?)\s*```/);
    const jsonText = jsonMatch ? jsonMatch[1] : response;
    const parsed = JSON.parse(jsonText);
    
    console.log('\n✅ Parsed successfully:');
    console.log(`   Summary: ${parsed.overallSummary}`);
    console.log(`   Insights: ${Object.keys(parsed.insights).length} categories`);
    console.log(`   Recommendations: ${parsed.recommendations.length} items`);
    
    return true;
  } catch (error) {
    console.error('❌ Test failed:', error.message);
    return false;
  }
}

/**
 * Run all tests
 */
async function runAllTests() {
  console.log('\n🚀 Starting LLM Service Tests...\n');
  
  const results = {
    matchAnalysis: false,
    matchPattern: false,
    yearlyAnalysis: false
  };

  // Run tests sequentially with delays to avoid rate limiting
  results.matchAnalysis = await testMatchAnalysis();
  await new Promise(resolve => setTimeout(resolve, 2000));
  
  results.matchPattern = await testMatchPattern();
  await new Promise(resolve => setTimeout(resolve, 2000));
  
  results.yearlyAnalysis = await testYearlyAnalysis();
  
  // Summary
  console.log('\n' + '='.repeat(60));
  console.log('📋 Test Summary');
  console.log('='.repeat(60));
  console.log(`Match Analysis:        ${results.matchAnalysis ? '✅ PASS' : '❌ FAIL'}`);
  console.log(`Match Pattern:         ${results.matchPattern ? '✅ PASS' : '❌ FAIL'}`);
  console.log(`Yearly Analysis:       ${results.yearlyAnalysis ? '✅ PASS' : '❌ FAIL'}`);
  console.log('='.repeat(60));
  
  const allPassed = Object.values(results).every(r => r);
  
  if (allPassed) {
    console.log('\n🎉 All tests passed! LLM services are working correctly.\n');
    process.exit(0);
  } else {
    console.log('\n⚠️  Some tests failed. Check the logs above for details.\n');
    process.exit(1);
  }
}

// Run tests
runAllTests().catch(error => {
  console.error('\n💥 Unexpected error:', error);
  process.exit(1);
});
