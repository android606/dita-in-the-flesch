<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:fn="http://myfunctions"
    exclude-result-prefixes="fn xs" version="2.0">

    <!-- ##
         ## DITAtoFK.xsl
         ##
         ## Calculates a Flesch-Kincaid score from a merged XML file
         ##
         -->
    
    <!-- // PARAMETERS // -->
    <xsl:param name="detail" select="2"/>

    <!-- // INCLUDES // -->

    <!-- // DECLARATIONS // -->
    <!-- Syllable Dictionary -->
    <xsl:variable name="syllables-dict" select="document('SyllableDictionary.xml')"/>
    <xsl:key name="syllables-key" match="words/syllables" use="@word"/>

    <!-- ## 
         ## Variables and settings
         ## -->
    <!-- // OUTPUT CONFIGURATION // -->
    <!-- output as xml -->
    <xsl:output method="xml" indent="no"/>
    <!-- remove empty white space elements-->
    <xsl:strip-space elements="*"/>

    <!-- NEWLINE -->
    <xsl:variable name="newline">
        <xsl:text>&#10;</xsl:text>
    </xsl:variable>

    <!-- #
         # Element whitelists
         #
         # These only have to include elements that are valid below the topic level.
         # -->
    <!-- // ElementTypesToDisplay //
         List of the elements that will be displayed, but not necessarily counted. -->
    <xsl:variable name="ElementsToDisplay"
        select="('cmd','context','entry','fig','image','li','note','p')"/>

    <!-- // ElementsToTabulate //
         Elements we want to count in our scoring results. 
         These won't be displayed unless they're listed in ElementTypesToDisplay, too. -->
    <xsl:variable name="ElementsToTabulate" select="('cmd','context','entry','li','note','p')"/>

    <!-- // ElementsToIgnore //
         List of the elements that we want to skip completely.
         Any elements in this list will not be counted or displayed. -->
    <xsl:variable name="ElementsToIgnore"
        select="('b','colspec','example','i','image','indexterm','info','ol','ph','row','sup','table','tbody','tgroup','thead','title','tm','u','section','step','steps','stepxmp','ul','xref')"/>

    <xsl:variable name="topicid"/>



    <!-- ##
         ##
         ## TEMPLATES
         ##
         ## -->

    <!-- // MAIN ENTRY POINT // -->
    <xsl:template match="/">
        <xsl:variable name="stage1-data">
<FKroot>
    <meta>
        <title>
            <xsl:value-of select="/bookmap/booktitle/mainbooktitle | /map/title"/>            
        </title>
        <xsl:value-of select="$newline"/>
        <alttitles>
            <xsl:value-of select="/bookmap/booktitle/booktitlealt[1] | /map/data[@name='titlealt'][1]"/>            
        </alttitles>
        <xsl:value-of select="$newline"/>
        <alttitles>
            <xsl:value-of select="/bookmap/booktitle/booktitlealt[2] | /map/data[@name='titlealt'][2]"/>            
        </alttitles>
        <xsl:value-of select="$newline"/>
        <!--        <alttitles>
            <xsl:value-of select="/bookmap/booktitle/mainbooktitle | /map/title"/>
        </alttitles>
        <alttitles>
            <xsl:value-of select="/bookmap/booktitle/booktitlealt | /map/topicmeta/navtitle"/>            
        </alttitles> -->
    </meta>
        <data>
            <xsl:choose>
                <!-- If this is a bookmap, it may have chapters. If so, tally stats by chapter -->
                <xsl:when test="//chapter">
                    <xsl:apply-templates select=".//frontmatter | .//chapter"/>                    
                </xsl:when>
                <!-- Otherwise, this is a map, so tally by topic -->
                <xsl:otherwise>
                    <xsl:apply-templates select=".//concept|.//reference|.//task|.//topic"/>
                </xsl:otherwise>
            </xsl:choose>
        </data>
        <xsl:value-of select="$newline"/>
</FKroot>
        </xsl:variable>
        <xsl:result-document href="stage1-data.xml"><xsl:copy-of select="$stage1-data"/></xsl:result-document>
        <xsl:call-template name="output-stats">
            <xsl:with-param name="the-data" select="$stage1-data"/>
        </xsl:call-template>
        
    </xsl:template>


    <!-- ########## STAGE 1 TEMPLATES ##########
         # 
         # Format the text in neat and tidy blocks and sentences, with per-sentence stats, so we can get cumulative stats easily in stage 2.
         # 
         # -->
    

    <!-- // Template: chapters // -->
    <xsl:template match="frontmatter | chapter">
<chapter>
    <title>
        <xsl:choose>
            <xsl:when test="@navtitle"><xsl:value-of select="@navtitle"/></xsl:when>
            <xsl:when test="topicmeta/navtitle"><xsl:value-of select="topicmeta/navtitle"/></xsl:when>
            <xsl:when test="self::frontmatter">(Frontmatter)</xsl:when>
            <xsl:otherwise>(No Title / <xsl:value-of select="@id"/>)</xsl:otherwise>
        </xsl:choose>
    </title>
    <xsl:apply-templates select=".//concept|.//reference|.//task|.//topic"/>
</chapter>
<xsl:value-of select="$newline"/>        
    </xsl:template>



    <!-- // Template: topics // -->
    <xsl:template match="concept|reference|task|topic">
<topic><xsl:message>((<xsl:value-of select="name(.)"/>: <xsl:value-of select="title"/>))</xsl:message>
    <xsl:attribute name="id"><xsl:value-of select="@id"/></xsl:attribute>
    <xsl:attribute name="type"><xsl:value-of select="name(.)"/></xsl:attribute>
    <title><xsl:value-of select="title"/></title>
    <xsl:apply-templates select=".//*[name(.)=$ElementsToTabulate]"/>
</topic>
<xsl:value-of select="$newline"/>
    </xsl:template>    
    


    <!-- // Template: block elements that we want to tabulate and display (listed in $ElementsToTabulate) 
            Don't include block elements without text
            Don't include block elements nested inside other block elements (because we already get the text from all children of block elements)
        // -->
    <!-- match="*[name(.) = $ElementsToTabulate][not(string-length(normalize-space(.)) = 0)][not(ancestor::*[name(.) = $ElementsToTabulate])] -->
    <xsl:template match="*[name(.) = $ElementsToTabulate][not(string-length(normalize-space(.)) = 0)]">
<block>
    <xsl:attribute name="type"><xsl:value-of select="name(.)"/></xsl:attribute>
    <xsl:for-each select="fn:split-sentences(string-join(.//text(),' '))">
        <xsl:if test="fn:count-words(.) > 0">
            <sentence>
                <xsl:attribute name="words" select="fn:count-words(.)"/>
                <xsl:attribute name="syllables" select="fn:count-syllables(.)"/>
                <xsl:value-of select="."/>
            </sentence>            
        </xsl:if>
    </xsl:for-each>
</block>
<xsl:value-of select="$newline"/>
    </xsl:template>


    <!-- // elements we're deliberately not displaying // -->
    <xsl:template match="*[name(.)=$ElementsToIgnore]" priority="20"/>
    <xsl:template match="*[ancestor::*[@processing-role='resource-only']]" priority="10">
        <xsl:message>Ignored 'resource-only' (probably localization): <xsl:value-of select="@id"/></xsl:message>
    </xsl:template>
    <xsl:template match="*[@outputclass='Manually_Placed']" priority="10">
        <xsl:message>Ignored 'Manually_Placed': <xsl:value-of select="@id"/></xsl:message>
    </xsl:template>
    

    <!-- // elements that made it to the display stage, but that we don't recognize: display a warning message. // -->
    <xsl:template match="*" mode="tabulate" priority="10">
        <xsl:value-of select="$newline"/>
        <ERROR>
    <xsl:value-of
        select="concat(' WARNING UNRECOGNIZED ELEMENT: ','&#x005B;',name(.),' #',@id,'&#x005D; ')"
    />
</ERROR>
        <xsl:value-of select="$newline"/>
    </xsl:template>



    <!-- #
         # STAGE 1 FUNCTIONS
         # -->
    <!-- // Function: split-sentences / Function to split a block of text into sentences // -->
    <xsl:function name="fn:split-sentences">
        <xsl:param name="text-block" as="xs:string"/>
        <!-- First, let's strip out all the crazy characters (leave only word characters and .:!?) and normalize the spaces -->
        <xsl:variable name="text-stripped" select="normalize-space(
                                                        replace($text-block,'[^\w .:!?]+','')
                                                    )"/>
        
        <!--// Holy crap regular expressions can get unruly fast
            //
            // This is supposed to split a string "paragraph" into "sentences".
            // There's no foolproof way to do this. English is just too complicated, and we bend the rules a lot in our user manuals. 
            // It would be nice if sentences always ended with one of these ->.?! and a space following, but it's not that simple.
            // A lot of our sentences, especially in lists, have no punctuation at all.  We use things like "Warning:", which is not
            // a sentence, but then also things like "This is a list of warnings you should be aware of:" which _is_ a sentence.
            //
            // How do we reliably detect the difference without some kind of fancy semantics checking code, or something that's aware
            // of grammar rules and common exceptions?
            //
            // Well, we can't. So, we have to fudge it a bit.
            //
            // 1) I don't consider word groups with two words or less to be sentences. This helps to prevent us from thinking 
            //    abbreviations are sentences.
            // 2) Sentences end with punctuation and a space, or we'll call it a sentence if we make it to the end of the string,
            //    and there's no punctuation
            // 3) Words can contain ":", so if we see something like "Warning: this thing is dangerous" we know it's not two sentences.
            // 4) They can also contain square brackets- this is mainly so GC extracts with all their brackets don't break our toys.
            //
            // What else? Hmm...  I don't know.  I'll probably think of more six months from now.
            //
            // # So, here's the whole expression
            // # '(([\[\]\(\)'',;/\c]+?[\s.:])|([\[\]\(\)'',;/\c]+?)){2,}'
            //
            // # Let's break it down for "clarity"
            //
            // 
            //       (
            //         (                      -|
            //           [\[\]\(\)'',;/\c]     | Match any of the following characters: [ ] ( ) ' , / A-Z a-z 0-9 - . _ :
            //           +?                    | repeated one or more times (lazy mode)
            //           [\s.:!?]              | followed by whitespace or one of the following characters: . : ! ?
            //         )                      -|
            //       |                      -| OR
            //         (                      -|
            //           [\[\]\(\)'',;/\c]     | Match any of the following characters: [ ] ( ) ' , / A-Z a-z 0-9 - . _ :
            //           +?                    | repeated one or more times (lazy mode), right to the end of the line 
            //         )                      -| that way, we detect lines with no punctuation as sentences, too.
            //       ){2,}                  -| Only match if there are two or more words
            //     
            // -->
        <xsl:variable name="split-string" as="xs:string*">
        <xsl:analyze-string select="$text-stripped" regex="(([\[\]\(\)&apos;,;/\c]+?[\s.:!?])|([\[\]\(\)&apos;,;/\c]+?)){{2,}}">
            <xsl:matching-substring>
                <xsl:value-of select="."/>
            </xsl:matching-substring>
        </xsl:analyze-string>
        </xsl:variable>
        <xsl:sequence select="$split-string"/>
    </xsl:function>
    
    
    <!-- // Function: count-words / Function to count words in a string // -->
    <xsl:function name="fn:count-words">
        <xsl:param name="sentence"/>
        <xsl:value-of select="count(tokenize(normalize-space($sentence),'[-\s]+'))"/>
    </xsl:function>
    


    <!-- // Function: count-syllables // -->
    <!-- * Depends on fn:count-syllables-in-word * -->
    <!-- Give it a word or list of words, it gives back the total number of syllables. -->
    <xsl:function name="fn:count-syllables">
        <xsl:param name="wordsstring"/>
        <!-- remove non-alpha characters from string and make it all lowercase -->
        <xsl:variable name="uppercase-string" select="upper-case(replace($wordsstring,'[^\w ]',' '))"/>
        
        <!-- convert string to list of words -->
        <xsl:variable name="wordslist" select="tokenize(normalize-space($uppercase-string),' ')"/>



            
            <!-- Iterate over words in list and get syllable count for each one -->
            <xsl:variable name="syllable-counts" as="xs:float*">
                <xsl:for-each select="$wordslist">
                    <xsl:copy-of select="fn:count-syllables-in-word(.)"/>
                </xsl:for-each>
            </xsl:variable>        
                    
            <!-- Output the total of all syllable counts -->
            <xsl:value-of select="sum($syllable-counts),$syllable-counts"/>
            
    </xsl:function>



    <!-- // Function: count-syllables-in-word // -->
    <!-- Give it a word it gives back the total number of syllables. -->
    <xsl:function name="fn:count-syllables-in-word">
        <!-- By hook or by crook, figure out the number of syllables in a word -->
        <xsl:param name="word"/>

        <xsl:variable name="function-result" as="xs:double+">
        <xsl:choose>
            <!-- When the word has no alphabetic characters, it's not a word. Return 0. -->
            <xsl:when test="not(matches($word, '^[a-zA-Z]+$'))">
                <xsl:value-of select="0"/>
            </xsl:when>
            
            <!-- When the word only has one or two letters, it's one syllable -->
            <xsl:when test="3 > string-length($word)">
                <xsl:value-of select="1"/>
            </xsl:when>
            
            <!-- When the word is in the dictionary, return the number of syllables from the dictionary -->
            <xsl:when test="key('syllables-key',$word,$syllables-dict)">
                <xsl:copy-of
                    select="key('syllables-key',$word,$syllables-dict)"/>
            </xsl:when>
            
            <!-- When the word ends with an "S", see if you can remove the S and find that in the dictionary. -->
            <xsl:when
                test="(substring($word, string-length($word),1) = 'S') 
                and (key('syllables-key',substring($word, 1, string-length($word)-1),$syllables-dict))">
                <xsl:copy-of
                    select="key('syllables-key',substring($word, 1, string-length($word)-1),$syllables-dict)"
                />
            </xsl:when>
            
            <!-- When the word ends with an "ED", see if you can remove the ED and find that in the dictionary. -->
            <xsl:when
                test="(substring($word, string-length($word)-1) = 'ED') 
                and (key('syllables-key',substring($word, 1, string-length($word)-2),$syllables-dict))">
                <xsl:copy-of
                    select="key('syllables-key',substring($word, 1, string-length($word)-2),$syllables-dict)"
                />
            </xsl:when>
            
            <!-- When the word ends with an "ER", see if you can remove the ER and find that in the dictionary. -->
            <xsl:when
                test="(substring($word, string-length($word)-1) = 'ER') 
                and (key('syllables-key',substring($word, 1, string-length($word)-2),$syllables-dict))">
                <xsl:copy-of
                    select="key('syllables-key',substring($word, 1, string-length($word)-2),$syllables-dict)"
                />
            </xsl:when>
            
            <!-- When the word ends with an "ING", see if you can remove the ING and find that in the dictionary. -->
            <xsl:when
                test="(substring($word, string-length($word)-2) = 'ING') 
                and (key('syllables-key',substring($word, 1, string-length($word)-3),$syllables-dict))">
                <!-- Add 1 to the value in the dict, since "ING" adds a syllable to the word. -->
                <xsl:copy-of
                    select="key('syllables-key',substring($word, 1, string-length($word)-3),$syllables-dict) + 1"
                />
            </xsl:when>

            <!-- Otherwise, we didn't find it in the dictionary at all- just return a default of "2.121212",
                which is our magic code number that signifies a dictionary miss.
                Also, print a warning message so the user knows the word will be counted as one syllable. -->
            <xsl:otherwise>
                <xsl:value-of select="2.121212"/>
                <xsl:message>Not found in dictionary file: <xsl:value-of select="$word"/></xsl:message>
            </xsl:otherwise>
        </xsl:choose>
        </xsl:variable>
        
        <xsl:if test="$function-result[2]"><xsl:message>
            WARNING: Multiple dictionary matches on word: <xsl:value-of select="$word"/>
        </xsl:message></xsl:if>
        
        <xsl:value-of select="$function-result[1]"/>
    </xsl:function>
    
    



    <!-- ########## STAGE 2: TOTALS CALCULATION TEMPLATES ##########
         # 
         # -->
    
    <!-- // Template: output-stats - Display output statistics // -->
    <xsl:template name="output-stats">
        <xsl:param name="the-data"/>
        <xsl:choose>
            <xsl:when test="$detail = 0">
                <xsl:for-each select="$the-data/FKroot/data">
                    <xsl:call-template name="generate-document-stats"/>
                </xsl:for-each>                
            </xsl:when>
            <xsl:otherwise>
<HTML>
    <HEAD>
        <LINK rel="stylesheet" type="text/css" href="fkstyle.css"/>
    </HEAD>
    <BODY>
        <DIV class="BODY">
        <DIV class="title">
            <H2 class="title"><xsl:value-of select="$the-data/FKroot/meta/title"/></H2>
            <H2 class="title"><xsl:value-of select="$the-data/FKroot/meta/alttitles[1]"/> - 
                <xsl:value-of select="$the-data/FKroot/meta/alttitles[2]"/></H2>
            <H1 class="title">Flesch-Kincaid Readability Assessment</H1>
        </DIV>
        
        <!-- There's only one "data" element, but we have to use for-each to change context with call-template -->
        
        <DIV class="document-stats">
            <xsl:for-each select="$the-data/FKroot/data">
                <xsl:call-template name="generate-document-stats"/>
            </xsl:for-each>
        </DIV>
        <xsl:if test="$detail > 1">
        <DIV class="chapter-stats">
        <H3>Per-Section Scoring:</H3>
        <TABLE class="chapter-stats">
            <xsl:choose>
                <xsl:when test="$the-data/FKroot/data/chapter">
                    <xsl:for-each select="$the-data/FKroot/data/chapter">
                        <xsl:call-template name="generate-chapter-stats"/>
                    </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:for-each select="$the-data/FKroot/data/topic">
                        <xsl:call-template name="generate-topic-stats-maps"/>
                    </xsl:for-each>
                </xsl:otherwise>
            </xsl:choose>
        </TABLE>
        </DIV>
        </xsl:if>
<DIV class="footnote">Note: Readability scores in this analysis report were calculated using the Flesch-Kincaid Grade Level formula:
<PRE>FKRA Score = (0.39 x ASL) + (11.8 x ASW) - 15.59
Where: 
ASL = Total Words / Total Sentences
ASW = Total Syllables / Total Words
</PRE>         
See <a href="https://en.wikipedia.org/wiki/Flesch%E2%80%93Kincaid_readability_tests">https://en.wikipedia.org/wiki/Flesch–Kincaid_readability_tests</a>
    and <i>Kincaid JP, Fishburne RP Jr, Rogers RL, Chissom BS (February 1975). "Derivation of new readability formulas (Automated Readability Index, Fog Count and Flesch Reading Ease Formula) for Navy enlisted personnel" (PDF). Research Branch Report 8-75, Millington, TN: Naval Technical Training, U. S. Naval Air Station, Memphis, TN.</i>
    for more information.
            </DIV>
            <SUB>Report Generated <xsl:value-of select="current-dateTime()"/> by FKScore</SUB>
        </DIV>
    </BODY>
</HTML>                
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>



    <xsl:template name="generate-document-stats">
        <xsl:variable name="sentencecount" select="count(.//sentence)" as="xs:double"/>
        <xsl:variable name="wordcount" select="sum(.//sentence/@words)" as="xs:double"/>
        <xsl:variable name="syllablecount" select="sum(.//sentence/number(tokenize(@syllables,' ')[1]))" as="xs:double"/>
        <B>Full Document Score:  </B><xsl:value-of select="round(((.39 * ($wordcount div $sentencecount)) + (11.8 * ($syllablecount div $wordcount)) - 15.59) * 100) div 100"/><xsl:element name="BR"/>
        

<xsl:if test="$detail > 2">
    <H3>Document Statistics</H3>
    
Averaged over <xsl:value-of select="count(.//topic)"/> topics.<xsl:element name="BR"/>
        <xsl:element name="BR"/>
        
ASL: <xsl:value-of select="round($wordcount div $sentencecount * 100) div 100"/> average words per sentence<xsl:element name="BR"/>
ASW: <xsl:value-of select="round($syllablecount div $wordcount * 100) div 100"/> average syllables per word<xsl:element name="BR"/>

Words: <xsl:value-of select="round($wordcount)"/><xsl:element name="BR"/>
Paragraphs: <xsl:value-of select="count(.//block)"/><xsl:element name="BR"/>
Sentences: <xsl:value-of select="round($sentencecount)"/><xsl:element name="BR"/>
Syllables: <xsl:value-of select="round($syllablecount)"/><xsl:element name="BR"/>
</xsl:if>
    </xsl:template>



    <xsl:template name="generate-chapter-stats">
        <xsl:variable name="sentencecount" select="count(.//sentence)" as="xs:double"/>
        <xsl:variable name="wordcount" select="sum(.//sentence/@words)" as="xs:double"/>
        <xsl:variable name="syllablecount" select="sum(.//sentence/number(tokenize(@syllables,' ')[1]))" as="xs:double"/>
        <TR class="section-title"><TD><B><xsl:if test="not(normalize-space(title))"><i>(NO TITLE)</i></xsl:if><xsl:value-of select="title"/></B></TD>
        <TD><xsl:value-of select="round(((.39 * ($wordcount div $sentencecount)) + (11.8 * ($syllablecount div $wordcount)) - 15.59) * 100) div 100"/></TD>
        </TR>    
        <xsl:if test="$detail > 2">
            <TR><TD colspan="2" class="chapter-stats-detail">
        ASL: <xsl:value-of select="round($wordcount div $sentencecount * 100) div 100"/> average words per sentence (sentence length)<xsl:element name="BR"/>
        ASW: <xsl:value-of select="round($syllablecount div $wordcount * 100) div 100"/> average syllables per word<xsl:element name="BR"/>
            
        Topics: <xsl:value-of select="count(.//topic)"/><xsl:element name="BR"/>
        Words: <xsl:value-of select="round($wordcount)"/><xsl:element name="BR"/>
        Paragraphs: <xsl:value-of select="count(.//block)"/><xsl:element name="BR"/>
        Sentences: <xsl:value-of select="round($sentencecount)"/><xsl:element name="BR"/>
        Syllables: <xsl:value-of select="round($syllablecount)"/><xsl:element name="BR"/>
            </TD></TR></xsl:if>
        <xsl:if test="$detail > 3">
            <TR><TD colspan="2" class="topic-stats">
                <xsl:for-each select="topic">
                    <xsl:call-template name="generate-topic-stats"/>
                </xsl:for-each>
            </TD></TR>
        </xsl:if>
        <TR><TD><xsl:element name="BR"/></TD></TR>
    </xsl:template>
    

    
    <xsl:template name="generate-topic-stats-maps">
        <xsl:variable name="sentencecount" select="count(.//sentence)" as="xs:double"/>
        <xsl:variable name="wordcount" select="sum(.//sentence/@words)" as="xs:double"/>
        <xsl:variable name="syllablecount" select="sum(.//sentence/number(tokenize(@syllables,' ')[1]))" as="xs:double"/>
        <TR class="section-title"><TD><B><xsl:if test="not(normalize-space(title))"><i>(NO TITLE)</i></xsl:if><xsl:value-of select="title"/></B></TD>
            <TD><xsl:value-of select="round(((.39 * ($wordcount div $sentencecount)) + (11.8 * ($syllablecount div $wordcount)) - 15.59) * 100) div 100"/></TD>
        </TR>    
        <xsl:if test="$detail > 2">
            <TR><TD colspan="2" class="chapter-stats-detail">
                ASL: <xsl:value-of select="round($wordcount div $sentencecount * 100) div 100"/> average words per sentence<xsl:element name="BR"/>
                ASW: <xsl:value-of select="round($syllablecount div $wordcount * 100) div 100"/> average syllables per word<xsl:element name="BR"/>
                
                Words: <xsl:value-of select="round($wordcount)"/><xsl:element name="BR"/>
                Paragraphs: <xsl:value-of select="count(.//block)"/><xsl:element name="BR"/>
                Sentences: <xsl:value-of select="round($sentencecount)"/><xsl:element name="BR"/>
                Syllables: <xsl:value-of select="round($syllablecount)"/><xsl:element name="BR"/>
            </TD></TR></xsl:if>
        <xsl:if test="$detail > 3">
            <TR><TD colspan="2" class="block-stats">
                <xsl:for-each select="block">
                    <xsl:call-template name="generate-block-stats"/>
                </xsl:for-each>
            </TD></TR>
        </xsl:if>
        <TR><TD><xsl:element name="BR"/></TD></TR>
    </xsl:template>
    
    
    
    <xsl:template name="generate-topic-stats">
        <xsl:variable name="sentencecount" select="count(.//sentence)" as="xs:double"/>
        <xsl:variable name="wordcount" select="sum(.//sentence/@words)" as="xs:double"/>
        <xsl:variable name="syllablecount" select="sum(.//sentence/number(tokenize(@syllables,' ')[1]))" as="xs:double"/>
        
        <H5>Topic: <xsl:if test="not(normalize-space(title))"><i>(NO TITLE)</i></xsl:if><xsl:value-of select="title"/></H5>
        Score: <xsl:value-of select="round(((.39 * ($wordcount div $sentencecount)) + (11.8 * ($syllablecount div $wordcount)) - 15.59) * 100) div 100"/>
        (ASL: <xsl:value-of select="round($wordcount div $sentencecount * 100) div 100"/>, 
        ASW: <xsl:value-of select="round($syllablecount div $wordcount * 100) div 100"/>)<xsl:element name="BR"/>
        
        <xsl:if test="$detail > 4">
        Sentences: <xsl:value-of select="$sentencecount"/><xsl:element name="BR"/>
        Words: <xsl:value-of select="$wordcount"/><xsl:element name="BR"/>
        Syllables: <xsl:value-of select="$syllablecount"/><xsl:element name="BR"/>
        </xsl:if>
        <xsl:if test="$detail > 5">
            <DIV class="block-stats">
            <xsl:for-each select="block">
               <xsl:call-template name="generate-block-stats"/>
            </xsl:for-each>
            </DIV>
        </xsl:if>
    </xsl:template>



    <xsl:template name="generate-block-stats">
        <B><U>Block / Paragraph # <xsl:value-of select="position()"/></U></B><xsl:element name="BR"/>
        <xsl:for-each select="sentence">
                <xsl:call-template name="generate-debug-stats"/>
            </xsl:for-each>
    </xsl:template>



    <xsl:template name="generate-debug-stats">
        <xsl:variable name="wordcount" select="sum(@words)" as="xs:double"/>
        <xsl:variable name="syllablecount" select="number(tokenize(@syllables,' ')[1])"/>
        <TABLE border="1" width="90%">
            <TR>
                <TD width="5%">S#<xsl:value-of select="position()"/></TD>
                <TD width="10%">ASW <xsl:value-of select="round($syllablecount div $wordcount * 100) div 100"/></TD>
                <TD><xsl:value-of select="."/></TD>
            </TR>
            <TR>
                <TD colspan="2">Syls: <xsl:value-of select="$syllablecount"/> / Words: <xsl:value-of select="$wordcount"/></TD>
                <TD>(<xsl:value-of select="tokenize(@syllables,' ')[1]"/>) <xsl:value-of select="tokenize(@syllables,' ')[position() > 1]"/></TD>
            </TR>
        </TABLE>
            
    </xsl:template>


    

    <!-- ########## UTILITY TEMPLATES ##########
         # 
         # -->

    <!-- // Default templates // -->
    <xsl:template match="*"/>

    <xsl:template match="text()">
        <xsl:value-of select="normalize-space(.)"/>
    </xsl:template>



</xsl:stylesheet>
