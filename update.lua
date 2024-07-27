-- Purpose: Update the reactor++ script.
fs=filesystem

pwd=os.getenv("PWD")
-- backup the current script
fs.rename(fs.concat(pwd,"reactor++.lua"),fs.concat(pwd,"reactor++.lua.bak")

-- download the new script
os.execute("wget https://raw.githubusercontent.com/LoseUFaith/Reactorplusplus/dev/reactor++.lua reactor++.lua")
print("Update complete!")
