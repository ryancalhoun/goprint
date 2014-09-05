goprint
=======

Chrome extension plus web service to print from ChromeOS without using Cloud Print.

## Rationale

I like the idea of a Chomebook. In fact I own two, one of them a desktop model. I use them as
thin clients to a variety of server machines at home and at work. However, I am extremely dissatisfied
both with Google's position on locking the print stack into Cloud Print, as well as the community's
apparent willingness to accept it.

I don't need to print to anywhere in the world. I need to print to a wifi printer sitting 20 feet
away on my local network. My documents don't need to fly across the public internet, through Google's
servers, just to end up back in my own house. Same goes for HP ePrint (although I will say the HP
client apps for other mobile devices are much more willing to work with just local wifi). And when
it comes time to print bank statements or tax documents, I don't want Google or HP or anyone else
handling my confidential material.

Since my printer is what Google calls a "legacy" printer, I need to run a separate print server
with Google's Cloud Print software on it, just to get the job back to my printer in the first place.

## Solution

A means to print web pages from ChromeOS, backed by a locally owned web service and connected
printer.

#### Extension

The Chrome extension uses the MHTML API, which packages all web resources into a single file. This
file is posted to a defined web service. A print preview window opens as the request is processed.

#### Preview

A javascript app which displays the document to be printed. Parameters include page ranges and
orientation. Printing the final document is initiated here as well.

#### Server

A web service which accepts MHTML and caches a PDF document. Preview requests serve up JPEG images
of each page. The print request produces a new PDF containing the selected page range and sends it
to its local print queue.

PhantomJS understands MHTML, and is used to rasterize the original PDF. Other PDF actions are done
using Poppler utils such as pdftoppm, pdfseparate, and pdfunite.

## TODO

A build/configure script.

