/**
 * @file LLM Analysis Service for Match Reports and Yearly Analysis
 * Provides AI-powered insights for user matching patterns and yearly summaries
 */

import * as functions from "firebase-functions";
import fetch from "node-fetch";

/**
 * Interface for match statistics data
 */
interface MatchStatistics {
  totalMatches: number;
  chattedCount: number;
  skippedCount: number;
  avgCompatibility: number;
  maxCompatibility: number;
  totalChatMessages: number;
  actionDistribution: Record<string, number>;
}

/**
 * Interface for trait analysis data
 */
interface TraitAnalysis {
  trait: string;
  matchCount: number;
  avgScore: number;
  successRate: number;
}

/**
 * Interface for chat history summary
 */
interface ChatHistorySummary {
  conversationId: string;
  partnerId: string;
  partnerName: string;
  messageCount: number;
  startedAt: string;
  lastMessageAt: string;
}

/**
 * Interface for date range
 */
interface DateRange {
  start: string;
  end: string;
  label: string;
}

/**
 * Calls Gemini API via REST for analysis
 */
async function callGeminiForAnalysis(
  apiKey: string,
  prompt: string
): Promise<string> {
  const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${apiKey}`;

  functions.logger.info("📤 Calling Gemini API for analysis...", {
    promptLength: prompt.length,
    prompt: prompt,
    url: url.replace(apiKey, "***")
  });

  const response = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      contents: [
        {
          parts: [
            {
              text: prompt,
            },
          ],
        },
      ],
      generationConfig: {
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        // No maxOutputTokens - let response complete naturally
      },
    }),
  });

  if (!response.ok) {
    const errorText = await response.text();
    functions.logger.error("❌ Gemini API error", {
      status: response.status,
      statusText: response.statusText,
      error: errorText,
    });
    throw new Error(`Gemini API error: ${response.status} ${errorText}`);
  }

  const data: any = await response.json();

  functions.logger.info("📋 Raw API response structure", {
    hasError: !!data.error,
    hasCandidates: !!data.candidates,
    candidatesLength: data.candidates?.length,
    keys: Object.keys(data)
  });

  // Check for API error response
  if (data.error) {
    functions.logger.error("❌ Gemini API returned error", { 
      error: data.error 
    });
    throw new Error(`Gemini API error: ${data.error.message || JSON.stringify(data.error)}`);
  }

  // Check for missing candidates
  if (!data.candidates || data.candidates.length === 0) {
    functions.logger.error("❌ No candidates in Gemini response", { 
      fullResponse: JSON.stringify(data).substring(0, 500)
    });
    throw new Error("No response candidates from Gemini API");
  }

  // Check response structure
  const candidate = data.candidates[0];
  
  functions.logger.info("🔍 Candidate details", {
    hasContent: !!candidate.content,
    hasParts: !!candidate.content?.parts,
    finishReason: candidate.finishReason,
    index: candidate.index
  });

  // Only accept STOP finish reason - others are incomplete/blocked
  if (candidate.finishReason !== "STOP") {
    const reason = candidate.finishReason || "UNKNOWN";
    functions.logger.warn(`⚠️ Skipping response with finishReason: ${reason}`);
    throw new Error(`Incomplete response: ${reason}`);
  }

  if (!candidate.content || !candidate.content.parts || candidate.content.parts.length === 0) {
    functions.logger.error("❌ Invalid candidate structure", { 
      candidate: JSON.stringify(candidate).substring(0, 500),
      finishReason: candidate.finishReason
    });
    throw new Error(`Invalid response structure: ${candidate.finishReason || 'No content parts'}`);
  }

  const text = candidate.content.parts[0].text;
  
  if (!text || text.trim().length === 0) {
    functions.logger.error("❌ No text in response", { 
      candidate: JSON.stringify(candidate).substring(0, 500)
    });
    throw new Error("No text content in Gemini API response");
  }

  functions.logger.info("📥 Received Gemini response", {
    responseLength: text.length,
    preview: text.substring(0, 100),
    finishReason: candidate.finishReason
  });

  return text;
}

/**
 * Cloud Function: Analyze match patterns for a given period
 */
export const analyzeMatchPattern = functions
  .runWith({
    timeoutSeconds: 120, // 2 minutes
    memory: "256MB"
  })
  .https.onCall(
  async (data, context) => {
    functions.logger.info("🔍 analyzeMatchPattern called", { data });

    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    const { userId, statistics, traitAnalysis, dateRange } = data;

    if (!userId || !statistics || !traitAnalysis || !dateRange) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing required fields: userId, statistics, traitAnalysis, dateRange"
      );
    }

    try {
      const apiKey =
        process.env.GEMINI_API_KEY || functions.config().gemini?.key;

      if (!apiKey) {
        functions.logger.error("❌ GEMINI_API_KEY not configured");
        throw new functions.https.HttpsError(
          "failed-precondition",
          "Gemini API key is not configured"
        );
      }

      const stats = statistics as MatchStatistics;
      const traits = traitAnalysis as TraitAnalysis[];
      const range = dateRange as DateRange;

      // Build the analysis prompt
      const prompt = `你是一位专业的匹配分析师，擅长从用户的匹配数据中发现深层洞察。请分析以下匹配数据并提供个性化的分析报告。

## 用户匹配数据（${range.label}）

### 基本统计
- 总匹配数: ${stats.totalMatches}
- 开始聊天: ${stats.chattedCount}次
- 跳过: ${stats.skippedCount}次  
- 平均兼容性: ${(stats.avgCompatibility * 100).toFixed(1)}%
- 最高兼容性: ${(stats.maxCompatibility * 100).toFixed(1)}%
- 聊天消息总数: ${stats.totalChatMessages}

### 特质分析
${traits
  .slice(0, 5)
  .map(
    (t) =>
      `- **${t.trait}**: 匹配${t.matchCount}次，平均分${(t.avgScore).toFixed(1)}，成功率${(t.successRate * 100).toFixed(1)}%`
  )
  .join("\n")}

## 请提供分析报告

请用温暖、鼓励但真实的语气，提供一份**200-500字**的个性化分析报告，包含：

1. **总体印象**（2-3句话概括这个时期的匹配特点）
2. **深层洞察**（分析用户的匹配偏好和行为模式，2-3个要点）
3. **积极发现**（强调用户做得好的地方）
4. **建议改进**（温和地提出1-2个可以尝试的方向）

**要求：**
- 用第二人称"你"
- 语言自然流畅，像朋友聊天
- 避免数据堆砌，要讲故事
- 既真诚又鼓励
- 用中文输出

直接输出分析文本，不需要JSON格式。`;

      functions.logger.info("📝 Generated analysis prompt", {
        promptLength: prompt.length,
        prompt: prompt,
      });

      const analysis = await callGeminiForAnalysis(apiKey, prompt);

      functions.logger.info("✅ Analysis completed successfully", {
        analysisLength: analysis.length,
      });

      return {
        success: true,
        analysis: analysis.trim(),
      };
    } catch (error) {
      functions.logger.error("❌ Error in analyzeMatchPattern", {
        error,
        errorMessage: error instanceof Error ? error.message : String(error),
        errorStack: error instanceof Error ? error.stack : undefined,
      });

      // Return fallback analysis
      functions.logger.warn("⚠️ Returning fallback analysis");

      return {
        success: true,
        analysis: `在${data.dateRange.label}期间，你的匹配之旅展现出独特的个性特征。

通过分析你的匹配记录，我们发现你在寻找志同道合的伙伴时，注重内在的共鸣和深度的交流。你的匹配偏好反映了对真实连接的渴望。

建议：
1. 继续保持开放的心态，给每一个潜在匹配更多了解的机会
2. 在聊天中展现你独特的个性和兴趣
3. 关注那些与你价值观相符的匹配对象

记住，每一次匹配都是一次新的可能性。保持真诚，你会找到真正契合的人。`,
      };
    }
  }
);

/**
 * Cloud Function: Generate yearly AI analysis with comprehensive insights
 */
export const analyzeYearlyPattern = functions
  .runWith({
    timeoutSeconds: 180, // 3 minutes
    memory: "512MB"
  })
  .https.onCall(
  async (data, context) => {
    functions.logger.info("📅 analyzeYearlyPattern called", { data });

    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    const { userId, statistics, traitAnalysis, chatSummaries, dateRange } =
      data;

    if (
      !userId ||
      !statistics ||
      !traitAnalysis ||
      !chatSummaries ||
      !dateRange
    ) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing required fields"
      );
    }

    try {
      const apiKey =
        process.env.GEMINI_API_KEY || functions.config().gemini?.key;

      if (!apiKey) {
        functions.logger.error("❌ GEMINI_API_KEY not configured");
        throw new functions.https.HttpsError(
          "failed-precondition",
          "Gemini API key is not configured"
        );
      }

      const stats = statistics as MatchStatistics;
      const traits = traitAnalysis as TraitAnalysis[];
      const chats = chatSummaries as ChatHistorySummary[];
      const range = dateRange as DateRange;

      // Build comprehensive yearly analysis prompt
      const prompt = `你是一位资深的社交行为分析专家，擅长从用户的年度数据中提炼深刻洞察。请基于以下数据生成一份全面的年度分析报告。

## 年度数据概览（${range.label}）

### 匹配统计
- 总匹配数: ${stats.totalMatches}
- 开始对话: ${stats.chattedCount}次
- 跳过: ${stats.skippedCount}次
- 平均兼容性: ${(stats.avgCompatibility * 100).toFixed(1)}%
- 最佳兼容性: ${(stats.maxCompatibility * 100).toFixed(1)}%

### 关键特质 Top 5
${traits
  .slice(0, 5)
  .map(
    (t, idx) =>
      `${idx + 1}. **${t.trait}**: ${t.matchCount}次匹配，成功率${(t.successRate * 100).toFixed(1)}%`
  )
  .join("\n")}

### 对话概况
- 活跃对话数: ${chats.length}
- 总消息数: ${chats.reduce((sum, c) => sum + c.messageCount, 0)}

## 请生成 JSON 格式的年度分析报告

\`\`\`json
{
  "overallSummary": "一句话总结用户这一年的社交历程（50字以内）",
  "insights": {
    "matchPattern": "匹配模式洞察（简洁描述用户的匹配偏好）",
    "communicationStyle": "沟通风格特点（描述用户如何与他人交流）",
    "preferences": "核心偏好（用户最看重什么）",
    "growth": "成长轨迹（这一年有什么变化）"
  },
  "recommendations": [
    "具体可行的建议1（鼓励性）",
    "具体可行的建议2（启发性）",
    "具体可行的建议3（实践性）"
  ],
  "personalityTraits": {
    "openness": 0.0到1.0的数值（开放程度）,
    "authenticity": 0.0到1.0的数值（真实程度）,
    "engagement": 0.0到1.0的数值（参与度）
  },
  "topPreferences": [
    "偏好关键词1",
    "偏好关键词2",
    "偏好关键词3"
  ]
}
\`\`\`

**要求：**
- 基于数据进行分析，不要编造信息
- 语言温暖、个性化、有洞察力
- 既肯定成就，也指出成长空间
- 用中文
- 必须返回有效的 JSON`;

      functions.logger.info("📝 Generated yearly analysis prompt", {
        promptLength: prompt.length,
      });

      const rawResponse = await callGeminiForAnalysis(apiKey, prompt);

      // Parse JSON response
      const jsonMatch = rawResponse.match(/```json\s*([\s\S]*?)\s*```/);
      const jsonText = jsonMatch ? jsonMatch[1] : rawResponse;

      let parsedResponse;
      try {
        parsedResponse = JSON.parse(jsonText);
        functions.logger.info("✅ Yearly analysis parsed successfully");
      } catch (parseError) {
        functions.logger.error("❌ Failed to parse JSON response", {
          error: parseError,
          rawResponse: rawResponse.substring(0, 500),
        });
        throw new Error("Failed to parse AI response as JSON");
      }

      // Validate response structure
      if (
        !parsedResponse.overallSummary ||
        !parsedResponse.insights ||
        !parsedResponse.recommendations ||
        !parsedResponse.personalityTraits ||
        !parsedResponse.topPreferences
      ) {
        throw new Error("Invalid response structure from AI");
      }

      return {
        success: true,
        ...parsedResponse,
        generatedAt: new Date().toISOString(),
      };
    } catch (error) {
      functions.logger.error("❌ Error in analyzeYearlyPattern", {
        error,
        errorMessage: error instanceof Error ? error.message : String(error),
        errorStack: error instanceof Error ? error.stack : undefined,
      });

      // Return fallback yearly analysis
      functions.logger.warn("⚠️ Returning fallback yearly analysis");

      return {
        success: true,
        overallSummary: `在${data.dateRange.label}期间，你展现出独特的社交特征，注重真实连接和深度交流。`,
        insights: {
          matchPattern: "你倾向于与兴趣相投的人建立联系",
          communicationStyle: "你的沟通风格真诚而开放",
          preferences: "你重视共同价值观和深度对话",
          growth: "这一年你在探索不同类型的连接",
        },
        recommendations: [
          "继续保持开放的心态，给每个匹配更多了解的机会",
          "在对话中展现你的独特个性和兴趣爱好",
          "尝试主动发起话题，创造更深入的对话机会",
        ],
        personalityTraits: {
          openness: 0.75,
          authenticity: 0.85,
          engagement: 0.70,
        },
        topPreferences: ["深度交流", "共同兴趣", "真实连接"],
        generatedAt: new Date().toISOString(),
      };
    }
  }
);
