import json
import re
import os
from typing import Optional, Dict, Any
from pathlib import Path


class RealLLMClient:
    """
    Unified LLM client supporting multiple providers.
    Supports: OpenAI, Google Gemini, Anthropic Claude
    """
    
    def __init__(self, provider: str, model: str, api_key: Optional[str] = None):
        """
        Initialize LLM client.
        
        Args:
            provider: "openai", "gemini", or "anthropic"
            model: Model ID (e.g., "gpt-4", "gemini-pro", "claude-3-opus")
            api_key: API key (if None, uses environment variable)
        """
        self.provider = provider.lower()
        self.model = model
        self.api_key = api_key or self._get_api_key_from_env()
        
        # Initialize provider-specific client
        if self.provider == "openai":
            self._init_openai()
        elif self.provider == "gemini":
            self._init_gemini()
        elif self.provider == "anthropic":
            self._init_anthropic()
        else:
            raise ValueError(f"Unsupported provider: {provider}")
    
    def _get_api_key_from_env(self) -> str:
        """Get API key from environment variable."""
        env_vars = {
            "openai": "OPENAI_API_KEY",
            "gemini": "GEMINI_API_KEY",
            "anthropic": "ANTHROPIC_API_KEY"
        }
        env_var = env_vars.get(self.provider)
        if not env_var:
            raise ValueError(f"Unknown provider: {self.provider}")
        
        api_key = os.getenv(env_var)
        if not api_key:
            raise ValueError(f"API key not found. Set {env_var} environment variable.")
        
        return api_key
    
    def _init_openai(self):
        """Initialize OpenAI client."""
        try:
            from openai import OpenAI
            self.client = OpenAI(api_key=self.api_key)
        except ImportError:
            raise ImportError("OpenAI library not installed. Run: pip install openai")
    
    def _init_gemini(self):
        """Initialize Google Gemini client."""
        try:
            import google.genai as genai
            
            # Configure API key (works for both old and new versions)
            genai.configure(api_key=self.api_key)
            
            # Create model instance
            self.client = genai.GenerativeModel(self.model)
            
        except ImportError:
            raise ImportError("Google Generative AI library not installed. Run: pip install google-generativeai")
        except AttributeError:
            # Fallback for newer SDK versions
            try:
                from google import genai as new_genai
                
                # New SDK style (google-genai >= 1.0.0)
                self.new_client = new_genai.Client(api_key=self.api_key)
                self.client = None  # Mark as using new client
                
            except ImportError:
                raise ImportError(
                    "Could not initialize Gemini client. "
                    "Try: pip install --upgrade google-generativeai"
                )
    
    def _init_anthropic(self):
        """Initialize Anthropic Claude client."""
        try:
            from anthropic import Anthropic
            self.client = Anthropic(api_key=self.api_key)
        except ImportError:
            raise ImportError("Anthropic library not installed. Run: pip install anthropic")
    
    def complete(self, system_prompt: str, user_prompt: str, **kwargs) -> str:
        """
        Generate completion from LLM.
        
        Args:
            system_prompt: System/instruction prompt
            user_prompt: User query/task
            **kwargs: Provider-specific parameters (temperature, max_tokens, etc.)
        
        Returns:
            Generated text response
        """
        if self.provider == "openai":
            return self._complete_openai(system_prompt, user_prompt, **kwargs)
        elif self.provider == "gemini":
            return self._complete_gemini(system_prompt, user_prompt, **kwargs)
        elif self.provider == "anthropic":
            return self._complete_anthropic(system_prompt, user_prompt, **kwargs)
        else:
            raise ValueError(f"Unsupported provider: {self.provider}")
    
    def _complete_openai(self, system_prompt: str, user_prompt: str, **kwargs) -> str:
        """OpenAI completion."""
        messages = [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt}
        ]
        
        response = self.client.chat.completions.create(
            model=self.model,
            messages=messages,
            temperature=kwargs.get("temperature", 0.7),
            max_tokens=kwargs.get("max_tokens", 4096)
        )
        
        return response.choices[0].message.content
    
    def _complete_gemini(self, system_prompt: str, user_prompt: str, **kwargs) -> str:
        """Google Gemini completion."""
        # Set default parameters.
        # Note: Gemini 1.5 Pro/Flash and 3.0 Pro support up to 64k/128k output tokens.
        # We set a high default (65536) to avoid truncation in complex reasoning tasks,
        # unless 'max_tokens' is explicitly provided in kwargs.
        temperature = kwargs.get("temperature", 0.7)
        max_tokens = kwargs.get("max_tokens", 65536)
        
        # Determine if JSON mode should be enabled based on the system prompt.
        # This forces the model to output valid JSON, reducing parsing errors.
        is_json_mode = "json" in system_prompt.lower()

        try:
            # --- Path 1: New SDK (google-genai >= 1.0.0) ---
            # Check if using the new SDK client (usually initialized as 'new_client' or similar).
            if self.client is None and hasattr(self, 'new_client'):
                from google.genai.types import GenerateContentConfig

                # Prepare the configuration object.
                # In the new SDK, system_instruction is passed via the config.
                config = GenerateContentConfig(
                    system_instruction=system_prompt,
                    temperature=temperature,
                    max_output_tokens=max_tokens,
                    # Explicitly set MIME type for JSON if required.
                    response_mime_type="application/json" if is_json_mode else "text/plain"
                )

                response = self.new_client.models.generate_content(
                    model=self.model,
                    contents=user_prompt,
                    config=config
                )
                
                # Return the text content, handling potential empty responses (e.g., safety filters).
                return response.text if response.text else ""

            # --- Path 2: Old SDK (google-generativeai) ---
            else:
                import google.generativeai as genai

                # Create the generation configuration.
                generation_config = genai.GenerationConfig(
                    temperature=temperature,
                    max_output_tokens=max_tokens,
                    # JSON mode support varies by version in the old SDK.
                    # If supported, it's usually via response_mime_type="application/json".
                    response_mime_type="application/json" if is_json_mode else "text/plain"
                )

                # Initialize the model with system instructions.
                # Note: In the old SDK, system_instruction is immutable after initialization.
                # We re-instantiate the model here to apply the dynamic system_prompt.
                model_instance = genai.GenerativeModel(
                    model_name=self.model if isinstance(self.model, str) else "gemini-1.5-pro",
                    system_instruction=system_prompt
                )

                response = model_instance.generate_content(
                    user_prompt,
                    generation_config=generation_config
                )

                return response.text if response.text else ""

        except Exception as e:
            # Log the error for debugging purposes (e.g., API quota exceeded, network issues).
            print(f"[Gemini Error] {str(e)}")
            return ""
    
    def _complete_anthropic(self, system_prompt: str, user_prompt: str, **kwargs) -> str:
        """Anthropic Claude completion."""
        response = self.client.messages.create(
            model=self.model,
            system=system_prompt,
            messages=[{"role": "user", "content": user_prompt}],
            temperature=kwargs.get("temperature", 0.7),
            max_tokens=kwargs.get("max_tokens", 4096)
        )
        
        return response.content[0].text


def _extract_json_from_llm_response(response: str) -> Optional[Dict[str, Any]]:
    """
    Extract JSON object from LLM response text.
    
    LLMs often wrap JSON in markdown code blocks like:
    ```json
    { "key": "value" }
    ```
    
    This function handles multiple formats:
    1. JSON wrapped in ```json ... ```
    2. JSON wrapped in ``` ... ```
    3. Raw JSON object
    4. Multiple JSON objects (returns first valid one)
    
    Args:
        response: Raw text response from LLM
    
    Returns:
        Parsed JSON dict, or None if parsing fails
    """
    if not response:
        return None
    
    # Strategy 1: Try to find JSON in markdown code blocks
    code_block_patterns = [
        r'```json\s*(.*?)\s*```',  # ```json { ... } ```
        r'```\s*(.*?)\s*```',       # ``` { ... } ```
    ]
    
    for pattern in code_block_patterns:
        matches = re.findall(pattern, response, re.DOTALL | re.IGNORECASE)
        for match in matches:
            try:
                return json.loads(match.strip())
            except json.JSONDecodeError:
                continue
    
    # Strategy 2: Try to find raw JSON object (starts with { or [)
    json_patterns = [
        r'\{.*\}',  # { ... }
        r'\[.*\]',  # [ ... ]
    ]
    
    for pattern in json_patterns:
        matches = re.findall(pattern, response, re.DOTALL)
        for match in matches:
            try:
                return json.loads(match.strip())
            except json.JSONDecodeError:
                continue
    
    # Strategy 3: Try parsing entire response as JSON
    try:
        return json.loads(response.strip())
    except json.JSONDecodeError:
        pass
    
    # Strategy 4: Look for "json" keyword followed by JSON
    json_intro_pattern = r'(?:json|JSON|output|result)[\s:]*(\{.*\}|\[.*\])'
    matches = re.findall(json_intro_pattern, response, re.DOTALL | re.IGNORECASE)
    for match in matches:
        try:
            return json.loads(match.strip())
        except json.JSONDecodeError:
            continue
    
    # If all strategies fail
    print(f"[!] Warning: Could not extract JSON from LLM response")
    print(f"    Response preview: {response[:200]}...")
    # save response into "/local/home/ywu092/code/AssertLLM/AssertLLM2.0/debug_responses"
    # ########SAve response for debugging
    debug_dir = Path("debug_responses")
    debug_dir.mkdir(exist_ok=True)
    debug_file = debug_dir / f"response.json"
    with open(debug_file, "w", encoding="utf-8") as f:
        json.dump({"response": response}, f, indent=2)
    # ################################
    return None


def _extract_code_from_llm_response(response: str, language: str = "verilog") -> Optional[str]:
    """
    Extract code block from LLM response.
    
    Handles formats like:
    ```verilog
    module ...
    ```
    
    Args:
        response: Raw text response from LLM
        language: Expected language (verilog, systemverilog, python, etc.)
    
    Returns:
        Extracted code string, or None if not found
    """
    if not response:
        return None
    
    # Try language-specific code block first
    patterns = [
        rf'```{language}\s*(.*?)\s*```',
        rf'```systemverilog\s*(.*?)\s*```',
        r'```verilog\s*(.*?)\s*```',
        r'```\s*(.*?)\s*```',
    ]
    
    for pattern in patterns:
        match = re.search(pattern, response, re.DOTALL | re.IGNORECASE)
        if match:
            return match.group(1).strip()
    
    # Fallback: Return entire response if no code blocks found
    print(f"[!] Warning: No code block found, returning raw response")
    return response.strip()


def _validate_json_structure(data: Dict, required_keys: list) -> bool:
    """
    Validate that JSON has required keys.
    
    Args:
        data: Parsed JSON dict
        required_keys: List of required key names
    
    Returns:
        True if all required keys present
    """
    if not isinstance(data, dict):
        return False
    
    missing_keys = [key for key in required_keys if key not in data]
    if missing_keys:
        print(f"[!] Warning: JSON missing required keys: {missing_keys}")
        return False
    
    return True