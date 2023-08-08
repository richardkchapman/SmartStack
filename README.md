# SmartStack
Lightroom plugin for automatically stacking bursts

There are 4 separate (but sort-of related) bits of functionality in here, that
help streamline my Lightroom workflow particularly when working with macro.

1. Import additional EXIF data into custom metadata fields
2. Use one of the above custome metadata fields to detect all the photos in
a burst, and group them into a stack.
3. Propogate Lightroom metadata from the top photo on a stack into the photos
in the stack
4. Open and select a stack when the current photo is selected (this is the
same as shift clicking the stack icon on the photo - but I wanted a keystroke,
and it's possible via Mac keyboard shortcuts menu to put one on this plugin
action.


This repository is mainly juet to keep track of this project for my own use,
but if anyone stubling across it finds it useful to them, then feel free
to take and adapt it to your needs. The following notes may help:

1. Some parts of this are Mac-specific. For example the use of scripting to
get Lightroom to do some things that the API does not support (but the 
menus do). 
2. Some parts of this are specific to the cameras I use (Olympus and Canon)
though should be readily adapted to other cameras if anyone wanted to
3. This plugin requires exiftool be installed and on the path.
4. The plugin will launch multiple copies of exiftool in parallel, to speed
things up. If your computer is less powerful than mine, you may not want
as many instances.
5. Configuration is all via editing the code. I have not as yet bothered to
put a user interface on.

