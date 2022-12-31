# EventGen

This is an experimental command line tool.
Using this command line tool, you can generate event types defined using Swift from event specifications defined using natural language.

This tool is based on the following blog post.

- https://techlife.cookpad.com/entry/2020/11/05/110000
- https://zenn.dev/satoshin21/articles/58e516dc7f8403

## Getting started

First, prepare the following markdown file in specific directory. 
In this file, write a description of the events to be sent from the application to the backend.

```md
# impression

This event is automatically sent by the system when any screen is displayed．

## Parameters

- screenName
  - type
    - string
  - nullable
    - false
  - description
    - the displayed screen name
- count
  - type
    - int
  - nullable
    - true
  - description
    - If this screen has been displayed in the past, indicate how many times it has been displayed

## Discussion

This event was called `shown` in the past

```

Then, execute the following command

```
# Markdown files are located in the ./Events
$ swift run eventgen prepare --inputPath ./Events --outputPath result.json        
$ swift run eventgen transpile --inputPath result.json --outputPath output.swift
```

Finally, you will get the following Swift file as output.swift.

```swift
struct GeneratedEvent: Loggable {
    let eventName: String
    let paramerters: [String: Sendasble]
}

extension GeneratedEvent {
    /// This event is automatically sent by the system when any screen is displayed．
    /// - Parameters:
    ///   - screenName: the displayed screen name
    ///   - count: If this screen has been displayed in the past, indicate how many times it has been displayed
    static func impression(screenName: String, count: Int?) -> Self {
        .init(
            eventName: "impression",
            parameters: [screenName: screenName, count: count]
        )
    }
}

``` 

This tool is experimental and may only work in certain cases.
If it does not work, there may be no explanation as to why it does not work.

## Customization

Prepare subcommand generates an JSON file as shown below. 
Then, the transpile subcommand generates a Swift file based on the file. Therefore, it is possible to generate and transpile an JSON file by oneself without using the Prepare subcommand. 
For example, it is possible to generate an intermediate file from a csv or xml file.

```json
[
   {
      "properties":[

      ],
      "name":"firstLaunch",
      "description":"Event sent when the user launches the application for the first time．",
      "discussion":""
   },
   {
      "properties":[
         {
            "nullable":false,
            "name":"screenName",
            "type":"string",
            "description":"the displayed screen name"
         },
         {
            "nullable":true,
            "name":"count",
            "type":"int",
            "description":"If this screen has been displayed in the past, indicate how many times it has been displayed"
         }
      ],
      "name":"impression",
      "description":"This event is automatically sent by the system when any screen is displayed．",
      "discussion":"This event was called `shown` in the past"
   }
]
```
