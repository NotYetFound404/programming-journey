# Follows Ollama Course – Build AI Apps Locally by FreeCodeCamp
# This script reads a grocery list from a file, categorizes and sorts the items using an AI model, 
# and then saves the output to another file.

import ollama
import os

# Define the AI model to use
MODEL = "llama3.2"

# Define file paths
INPUT_FILE = "./data/grocery_list.txt"
OUTPUT_FILE = "./data/outputed_list.txt"

# Check if the input file exists
if not os.path.exists(INPUT_FILE):
    print("Error: Input file does not exist.")
    exit(1)

# Read grocery items from the file
with open(INPUT_FILE, "r") as f:
    items = f.read().strip()

# Construct the prompt for the AI model
prompt = f"""
You are an assistant that categorizes and sorts grocery items.
Here is a list of grocery items:
{items}

Please:
1. Categorize these items into appropriate categories such as Produce, Dairy, Meat, Bakery, Beverages, etc.
2. Sort the items alphabetically within each category.
3. Present the categorized list in a clear and organized manner, using bullet points or numbers.
"""

try:
    # Generate response using Ollama
    response = ollama.generate(model=MODEL, prompt=prompt)
    generated_text = response.get("response", "")

    # Print and save the categorized list
    print("===== Categorized List: =====\n")
    print(generated_text)

    with open(OUTPUT_FILE, "w") as f:
        f.write(generated_text.strip())

    print("Categorization completed successfully!")
except Exception as e:
    print(f"Error: {e}")
