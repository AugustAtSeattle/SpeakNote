# import os
# from openai import OpenAI

# os.environ["ORGANIZATION_ID"] = "ORG_ID_HERE"
# os.environ["OPENAI_API_KEY"] = "API_KEY_HERE"
# print("good world")

# client = OpenAI(api_key=os.environ["OPENAI_API_KEY"],organization=os.environ["ORGANIZATION_ID"])


import openai
import os

# Ensure your OPENAI_API_KEY is set as an environment variable
openai.api_key = os.getenv("OPENAI_API_KEY")

def chat_with_openai(message, chat_log=None):
    try:
        # Setting up a chat
        response = openai.ChatCompletion.create(
            model="gpt-3.5-turbo",  # or use another model like "gpt-4" if available
            messages=[
                {"role": "system", "content": "You are a helpful assistant."},
                {"role": "user", "content": message}
            ] + ([] if chat_log is None else chat_log)
        )

        # Extracting the response
        answer = response['choices'][0]['message']['content']
        print("OpenAI says:", answer)

        # Returning the updated chat log
        return chat_log + [{"role": "user", "content": message}, {"role": "assistant", "content": answer}] if chat_log is not None else [{"role": "user", "content": message}, {"role": "assistant", "content": answer}]
    except Exception as e:
        print("Error:", e)

# Example usage
chat_log = None
chat_log = chat_with_openai("Can you tell me a joke?", chat_log)
