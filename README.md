## Introduction

Trying to solve the engineering challange posed by this website:
http://instagram-engineering.tumblr.com/post/12651721845/instagram-engineering-challenge-the-unshredder

It reads in the file (provided) and breaks it up into slices (tried the part about automatically finding the breaks but not as obvious as I thought).
Along the way various info printed.

Finally, writes out all the 2-slices and then the final reconstructed image.

Haven't yet solved the issue about determining where the image ends (the alg finds sequence pairs, which gives you a cylinder, but until you find the one that doesn't really match, you can't break it out to a flat image).

## Running It

"rake" and it does the rest
