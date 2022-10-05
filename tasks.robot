*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.Dialogs
Library             RPA.Robocorp.Vault


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Download the orders file
    Open the robot order website
    Maximize Browser Window
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the modal
        Fill the form    ${row}
        Preview the robot
        Wait Until Keyword Succeeds    1 min    2 sec    Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    [Teardown]    Close Browser


*** Keywords ***
Open the robot order website
    #https://robotsparebinindustries.com/#/robot-order
    ${secret}=    Get Secret    sites
    Open Available Browser    ${secret}[ordersite]

Ask download url
    Add heading    Give url for downloading orders csv
    Add text input    url    label=url
    ${result}=    Run dialog
    RETURN    ${result.url}

Download the orders file
    #https://robotsparebinindustries.com/orders.csv
    ${downloadurl}=    Ask download url
    Download    ${downloadurl}    overwrite=True

Get orders
    ${orders}=    Read table from CSV    orders.csv    header=True
    RETURN    ${orders}

Close the modal
    Click Button    xpath://*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]

Fill the form
    [Arguments]    ${row}
    Select From List By Value    head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    css:form > div:nth-child(3) > input:first-of-type    ${row}[Legs]
    Input Text    address    ${row}[Address]

Preview the robot
    Click Button    preview

Submit the order
    Click Button    order
    Wait Until Element Is Visible    id:order-completion

Store the receipt as a PDF file
    [Arguments]    ${orderid}
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${OUTPUT_DIR}${/}receipts${/}${orderid}.pdf
    RETURN    ${OUTPUT_DIR}${/}receipts${/}${orderid}.pdf

Take a screenshot of the robot
    [Arguments]    ${orderid}
    Screenshot    xpath://*[@id="robot-preview-image"]    ${OUTPUT_DIR}${/}screenshots${/}${orderid}.png
    RETURN    ${OUTPUT_DIR}${/}screenshots${/}${orderid}.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf    ${pdf}
    Add Watermark Image To Pdf    image_path=${screenshot}    output_path=${pdf}
    Close All Pdfs

Go to order another robot
    Click Button    order-another

Create a ZIP file of the receipts
    Archive Folder With Zip
    ...    ${OUTPUT_DIR}${/}receipts
    ...    ${OUTPUT_DIR}${/}PDFs.zip
