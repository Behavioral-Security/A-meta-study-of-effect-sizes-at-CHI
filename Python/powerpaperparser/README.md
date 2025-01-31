# PowerPaperParser

This is the PowerPaperParser Agent!
Be prepared!

Setup: Have the requirements.txt from the Python directory installed.

### *First Option:* Running via command line (single paper, output printed):

**Note: The topic extraction will not be applied!**

```
export OPENAI_API_KEY=YOUR_KEY
python main.py
```

### *Second Option:* Running the script without arguments (multiple papers supported):

*(Optional)* If the OpenAI Key is not set as an environment variable, make a file OPENAI_API_KEY with the key in it.

In src/settings, set the path (html_folder_path) to the folder with the HTML paper files.
Add the papers to be evaluated to the papers list (papers) with the .html ending.

```
python main_IDE.py
```

After executing, there should be a results folder with the extracted test data.
The result file name is equivalent to the HTML paper name but as a JSON.
There is also a .md file with equivalent name, which is a protocol of the conversation with the LLM.


