---
name: supermemory-search
description: Search the user's Supermemory knowledge base using the Supermemory API. Trigger this skill whenever the user wants to search their memory, recall something they've saved, look something up in their second brain, or asks questions like "what do I know about X", "find in my memory", "search supermemory", or "recall X". Always use this skill when the user's query implies retrieving personal saved knowledge rather than general web information.
---

# Supermemory Search Skill

Search across the user's personal Supermemory knowledge base and return relevant results.

## API Details

- **Endpoint**: `https://api.supermemory.ai/v4/search`
- **Method**: POST
- **Auth**: Bearer token in `Authorization` header
- **API Key**: `sm_Sfe8KkkT9wmkLoY3wp8SsZ_fzQ107Xw3X6VMZ2RB8fx3a5kGKODdYETCGySqf6v7KBpuv8yjRcMESJtpHeUNXWJ`

## Workflow

1. Extract the search query from the user's message
2. Call the Supermemory search API with the query
3. Parse and present the results clearly

## Implementation (bash)

```bash
curl --silent --location 'https://api.supermemory.ai/v4/search' \
  --header 'Content-Type: application/json' \
  --header 'Authorization: Bearer sm_' \
  --data "{\"q\": \"<USER_QUERY>\"}"
```

Replace `<USER_QUERY>` with the user's actual search input, properly escaped for JSON.

## Response Handling

- Parse the JSON response
- Extract and display relevant results (title, content snippet, source URL if present)
- If no results found, inform the user clearly
- If API returns an error, surface the error message helpfully

## Example Usage

User: "Search my memory for notes on React hooks"
→ Query: `React hooks`
→ Call API → Parse → Display matching saved notes/content

User: "What do I know about the Mango Giraffe pitch?"
→ Query: `Mango Giraffe pitch`
→ Call API → Parse → Display results

## Notes

- Keep queries concise and keyword-focused for best recall
- If the user's request is vague, clarify what to search for before calling the API
- Results are ranked by relevance by the Supermemory backend — present them in order
