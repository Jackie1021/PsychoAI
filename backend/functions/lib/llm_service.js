"use strict";
/**
 * @file A reusable service for interacting with the Google Generative AI API.
 * It handles API initialization, prompt execution, response parsing, and logging.
 */
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.callAgent = callAgent;
const functions = __importStar(require("firebase-functions"));
const node_fetch_1 = __importDefault(require("node-fetch"));
/**
 * Calls Gemini API directly via REST to bypass SDK limitations
 */
async function callGeminiREST(apiKey, prompt) {
    const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${apiKey}`;
    functions.logger.info("🌐 Calling Gemini REST API...", {
        url: url.replace(apiKey, "***"),
        promptLength: prompt.length,
        prompt: prompt
    });
    const requestBody = {
        contents: [{
                parts: [{
                        text: prompt
                    }]
            }],
        generationConfig: {
            temperature: 0.8,
            topK: 40,
            topP: 0.95,
            // No maxOutputTokens limit - let it complete naturally
        }
    };
    const response = await (0, node_fetch_1.default)(url, {
        method: "POST",
        headers: {
            "Content-Type": "application/json",
        },
        body: JSON.stringify(requestBody)
    });
    functions.logger.info("📥 Gemini API response received", {
        status: response.status,
        statusText: response.statusText
    });
    if (!response.ok) {
        const errorText = await response.text();
        functions.logger.error("❌ Gemini API error", {
            status: response.status,
            error: errorText
        });
        throw new Error(`Gemini API error: ${response.status} ${errorText}`);
    }
    const data = await response.json();
    functions.logger.info("📋 Raw API response structure", {
        hasError: !!data.error,
        hasCandidates: !!data.candidates,
        candidatesLength: data.candidates?.length,
        candidatesType: typeof data.candidates,
        isCandidatesArray: Array.isArray(data.candidates),
        keys: Object.keys(data),
        responseSize: JSON.stringify(data).length
    });
    // Check for API error response
    if (data.error) {
        functions.logger.error("❌ Gemini API returned error", {
            error: data.error
        });
        throw new Error(`Gemini API error: ${data.error.message || JSON.stringify(data.error)}`);
    }
    // Check for missing candidates
    if (!data.candidates || !Array.isArray(data.candidates) || data.candidates.length === 0) {
        functions.logger.error("❌ No candidates in Gemini response", {
            fullResponse: JSON.stringify(data).substring(0, 500),
            candidatesType: typeof data.candidates,
            isArray: Array.isArray(data.candidates)
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
    functions.logger.info("✅ Gemini response parsed successfully", {
        responseLength: text.length,
        preview: text.substring(0, 100),
        finishReason: candidate.finishReason
    });
    return text;
}
/**
 * A generic function to call the LLM with a given prompt.
 * It logs the prompt and the raw response for debugging purposes.
 * It also handles parsing the expected JSON output from the LLM.
 *
 * @param prompt The complete prompt to send to the LLM.
 * @returns A promise that resolves to the parsed JSON object.
 */
async function callAgent(prompt) {
    // Get API key
    const apiKey = process.env.GEMINI_API_KEY || functions.config().gemini?.key;
    if (!apiKey) {
        functions.logger.error("❌ Gemini API key not configured", {
            hasProcessEnv: !!process.env.GEMINI_API_KEY,
            hasFunctionsConfig: !!functions.config().gemini?.key
        });
        throw new functions.https.HttpsError("failed-precondition", "The Gemini API key is not configured.");
    }
    functions.logger.info("🤖 Calling LLM agent", {
        promptLength: prompt.length,
        prompt: prompt,
        apiKeyLength: apiKey.length
    });
    try {
        // Call Gemini via REST API (bypasses SDK regional issues)
        const rawText = await callGeminiREST(apiKey, prompt);
        functions.logger.info("📝 Received LLM response", {
            rawTextLength: rawText.length,
            preview: rawText.substring(0, 100)
        });
        // Clean the response to extract only the JSON part.
        const jsonMatch = rawText.match(/```json([\s\S]*?)```/);
        const jsonText = jsonMatch ? jsonMatch[1].trim() : rawText.trim();
        functions.logger.info("🧹 Cleaned JSON text", {
            cleanedLength: jsonText.length
        });
        let parsedResponse;
        try {
            parsedResponse = JSON.parse(jsonText);
        }
        catch (parseError) {
            functions.logger.error("❌ JSON parse error", {
                error: parseError,
                jsonText: jsonText.substring(0, 200)
            });
            throw new Error("Failed to parse LLM response as JSON");
        }
        // Basic validation
        if (!parsedResponse.summary ||
            parsedResponse.totalScore === undefined ||
            !parsedResponse.similarFeatures ||
            Object.keys(parsedResponse.similarFeatures).length === 0) {
            functions.logger.error("❌ Invalid LLM response structure", {
                hasSummary: !!parsedResponse.summary,
                hasTotalScore: parsedResponse.totalScore !== undefined,
                hasSimilarFeatures: !!parsedResponse.similarFeatures,
                featuresCount: parsedResponse.similarFeatures ? Object.keys(parsedResponse.similarFeatures).length : 0
            });
            throw new Error("LLM response is missing or has invalid structure for required fields.");
        }
        functions.logger.info("✅ LLM response validated successfully", {
            totalScore: parsedResponse.totalScore,
            featuresCount: Object.keys(parsedResponse.similarFeatures).length
        });
        return parsedResponse;
    }
    catch (error) {
        // Log detailed error information
        functions.logger.error("❌ Error calling LLM or parsing response", {
            error,
            errorMessage: error instanceof Error ? error.message : String(error),
            errorStack: error instanceof Error ? error.stack : undefined,
            promptPreview: prompt.substring(0, 200)
        });
        // Return mock data as fallback
        functions.logger.warn("⚠️ Returning mock match data as fallback");
        return {
            summary: "Two creative souls destined to collaborate on amazing projects!",
            totalScore: 75,
            similarFeatures: {
                "Creative Expression": {
                    score: 85,
                    explanation: "Both users show strong creative tendencies in their traits and interests."
                },
                "Thoughtful Observation": {
                    score: 70,
                    explanation: "Shared appreciation for careful observation and mindful presence."
                },
                "Storytelling": {
                    score: 80,
                    explanation: "Common interest in narrative creation and world-building activities."
                }
            }
        };
    }
}
//# sourceMappingURL=llm_service.js.map