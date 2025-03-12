import os
from openai import OpenAI
from dotenv import load_dotenv

load_dotenv()

def chat_with_ai(user_input):
    client = OpenAI(
        api_key=os.getenv("OPENAI_API_KEY")  # Ensure your API key is set
    )

    response = client.chat.completions.create(
        model="gpt-4o",
        messages=[
            {"role": "system", "content": "You are an allergy tracking assistant."},
            {"role": "user", "content": user_input}
        ]
    )

    return response.choices[0].message.content  # Extract AI response

# Example usage
user_input = "I think I'm allergic to peanuts. What should I do?"
print(chat_with_ai(user_input))
