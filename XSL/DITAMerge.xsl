<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE stylesheet [
<!ENTITY newline "&#10;" >
]>
<!--File Details
	Owner: LifeScan, Inc
	
	Revision History:  

	-->
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <xsl:output method="xml" encoding="UTF-8" indent="no" omit-xml-declaration="yes"/>
    
    <xsl:template match="node()|@*">
        <xsl:copy>
            <xsl:apply-templates  select="node()|@*"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="topicref">
        <topicref>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates select="document(@href)"/>
            <xsl:apply-templates/>
        </topicref>
    </xsl:template>
    
    <xsl:template match="mapref">
        <mapref>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates select="document(@href)"/>
            <xsl:apply-templates/>
        </mapref>
    </xsl:template>
    
    <xsl:template match="keydef[@href]">
        <xsl:choose>
            <!-- Embed the target inline if it's DITA -->
            <xsl:when test="matches(@href,'^.*\.xml$') or matches(@href,'^.*\.ditamap$') or matches(@href,'^.*\.map$')">
                <keydef>
                    <xsl:copy-of select="@*"/>
                    <xsl:apply-templates select="document(@href)/*/*"/>
                    <xsl:apply-templates/>
                </keydef>                
            </xsl:when>
            <!-- leave an href pointer if it's not DITA -->
            <xsl:otherwise>
                <xsl:comment> (Pointer to non-DITA follows) </xsl:comment>
                <keydef>
                    <xsl:attribute name="href" select="@href"/>
                </keydef>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="//processing-instruction()"/>
    <xsl:template match="*[contains(@audience,'TraceMatrix')]"/>
    <xsl:template match="//comment()">
        <xsl:comment><xsl:value-of select="."/>(merged via DITAmerge.xsl)</xsl:comment>
    </xsl:template>
    
</xsl:stylesheet>
