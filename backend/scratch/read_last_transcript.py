import json

transcript_path = r"C:\Users\chaud\.gemini\antigravity\brain\58252ddf-9f2b-48b2-920b-f4e0148a1c13\.system_generated\logs\transcript.jsonl"

try:
    with open(transcript_path, "r", encoding="utf-8") as f:
        lines = f.readlines()
    
    print(f"Total lines in transcript: {len(lines)}")
    # Print the last 15 lines/steps
    for idx, line in enumerate(lines[-20:]):
        try:
            data = json.loads(line)
            source = data.get("source", "unknown")
            step_type = data.get("type", "unknown")
            content = data.get("content", "")
            if content:
                # Truncate content for readability
                short_content = content[:300] + "..." if len(content) > 300 else content
                print(f"\n[{idx}] {source} ({step_type}):\n{short_content}")
            else:
                print(f"\n[{idx}] {source} ({step_type}) [No text content]")
        except Exception as e:
            print(f"Error parsing line: {e}")
except Exception as e:
    print(f"Failed to read file: {e}")
