from openai import OpenAI
import json
import os
import time

client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
print(os.getenv("OPENAI_API_KEY"))
# Ensure your OPENAI_API_KEY is set as an environment variable

def chat_with_openai(message, chat_log=None):
    try:
        # Setting up a chat
        response = client.chat.completions.create(
            model="gpt-3.5-turbo",  # or use another model like "gpt-4" if available
            messages=[
                {"role": "system", "content": "You are a helpful assistant."},
                {"role": "user", "content": message}
            ] + ([] if chat_log is None else chat_log)
        )

        # Extracting the response
        answer = response.choices[0].message.content
        print("OpenAI says:", answer)

        # Returning the updated chat log
        return chat_log + [
            {"role": "user", "content": message},
            {"role": "assistant", "content": answer}
        ] if chat_log is not None else [
            {"role": "user", "content": message},
            {"role": "assistant", "content": answer}
        ]
    except Exception as e:
        print("Error:", e)

# Example usage
chat_log = None
# chat_log = chat_with_openai("Can you tell me a joke?", chat_log)

#### playground for assistant
threadID = "thread_uGJNfSqI6764HKnlzhCIe8vc"
assistantID = "asst_RhSneInjXwiSf0O0cwwSRHrC"


def print_thread_messages(threadID=threadID):
    response = client.beta.threads.messages.list(thread_id=threadID)
    for data in response.data:
        for content in data.content:
            print(content.text.value)


def wait_on_run(run, threadID = threadID):
    while run.status == "queued" or run.status == "in_progress":
        run = client.beta.threads.runs.retrieve(
            thread_id=threadID,
            run_id=run.id,
        )
        time.sleep(0.5)
    return run


### https://platform.openai.com/docs/assistants/overview

## add a new message to a thread
message = client.beta.threads.messages.create(
    thread_id=threadID,
    role="user",
    content="buy a birthday cake before 5pm"
)

## run the thread for new message
run = client.beta.threads.runs.create(
  thread_id=threadID,
  assistant_id=assistantID
)

# Wait for completion
wait_on_run(run)

# list all messages in thread
print_thread_messages()

# # Retrieve all the messages added after our last user message
# messages = client.beta.threads.messages.list(
#     thread_id=thread.id, order="asc", after=message.id
# )


