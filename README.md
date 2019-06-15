# dita-in-the-flesch
A Flesch-Kincaid readability assessment generator for DITA, using XSLT 2.0

# Why does this exist?
In processing DITA documents for submission to various regulatory authorities, quantified readability is a common request. The usual process for generating this information is to copy and paste a document into Microsoft Word, edit it heavily, and then use the built in readability tools to get a score. There are a few problems with this:
1. The readability score in Word appears to be based on Flesch-Kincaid, but it doesn't actually say anywhere in the documentation that it is. Also, the document stats in Word don't give you enough information to generate an FK score yourself. So, there is no way to confirm how this score is actually being generated.
1. FK scores require countable sentences, words and syllables. Content like symbols, tables with numbers, representative placeholders, images, are all technically not countable by Flesh-Kincaid. (How many syllables are there in ":-)"? ) The exact way these types of things are treated by Word is unclear to me, but they do affect the score. I need more control and auditability than that.
1. The usual solution to these problems is to edit the documents manually to remove oddball content from the equation. The problem with this is that it's hard to define, communicate, and enforce any kind of standard about how to do this.

So, it makes some sense to create a tool to do it.

# The Tool:
The DITA FK tool is implemented as an XSLT stylesheet. It has been written for and tested with the Saxon PE 9.6 XSLT processor from Saxonica. AFAIK, it should work fine with the HE edition as well.

As input, the stylesheet requires a merged XML file in DITA format, with all of the topics and maps merged into a single file. (A stylesheet to perform that merge is also included.)

The FK Tool's output consists of an HTML file with the results of the analysis. For my purposes, I convert that HTML file into a PDF using a great tool called **wkhtmltopdf.exe**...but I can't include that here. You could also convert it to a PDF manually using a browser, or probably with html2fo and Apache FOP or Antenna House Formatter... I'm rambling.

# How to use it:
## Basic Operation
{TODO: Give step-by-step instructions to set-up and run the tool and get output.)

## Advanced Options
{TODO: Explain options and how to them}


