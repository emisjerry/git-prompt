##README

git-prompt.exe will generate a git-prompt.bat in your specified folder. After that, you can use git-prompt.bat to change DOS-box prompt whick embeded your .git branch name.

###Setup
1. Copy git-prompt.exe into **<Git install folder>\libexec\git-core**. We can use "**git prompt**" to execute this command from now on.
2. At firsttime run git prompt, git-prompt.ini will created in git-core folder. Modify it to change the PromptBatch, then excute git prompt again to generate git-prompt.bat to your specified folder.
3. From now on, use git-prompt.bat to change the prompt based on your brance name.

###Usage
```batchfile
rem 1. Generate git-prompt.bat
git prompt

rem 2. Change the prompt
git-prompt

rem Run in the same time
git prompt > chg.bat && chg.bat

rem Display the sort description
git prompt -?
```

###git-prompt.ini sample:
```INI
[Prompt]
DefaultFG=light green
DefaultBG=black
HighlightFG=light green
HighlightBG=black
HighlightFG.up-to-date=light cyan
HighlightBG.up-to-date=black
HighlightFG.behind=light red
HighlightBG.behind=black
HighlightFG.nonsync=light yellow
HighlightBG.nonsync=black
HighlightFG.ahead=light green
HighlightBG.ahead=black

PromptBatch=d:\util\git-prompt.bat
```

###Version info
* v0.01 2014/09/02 Initial version
