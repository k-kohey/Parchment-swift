require "csv"
require 'rake'

# Experimental Implemention

class String
    def camelize()
      self.split("_").map{|w| w[0] = w[0].upcase; w}.join
    end
end

interfaceStatement = []

CSV.foreach("event_list.csv", headers: true) do |row|
    event_name = row["Event name"].camelize()
    parameter_scheme = row["Parameter scheme"]

    FileUtils.mkdir_p("jsons")

    json_file_name = "#{event_name}.json"
    File.open("./jsons/#{json_file_name}", "w") do |f| 
        f.write(parameter_scheme.gsub(/“|”/, '"'))
        f.close
    end

    interfaceStatement.push """
    /// #{row["Description"]}
    /// 
    /// payload:
    ///
    /// ```
    #{parameter_scheme.lines.map { |line| "/// #{line}" }.join('')}
    /// ```
    static func #{event_name}(_ parameters: ParameterOf#{event_name}) -> Self {
        do {
            let dic = try JSONSerialization.jsonObject(with: try parameters.jsonData(), options: [])
            return .init(eventName: \"#{event_name}\", parameters: dic as? [String: Any] ?? [:]) 
        } catch {
            return .init(eventName: \"LoggerError\", parameters: [\"error\": error.localizedDescription]) 
        }
    }
    """
end

sh "quicktype ./jsons --out GeneratedEventPrameters.swift --type-prefix ParameterOf"
FileUtils.rm_rf("jsons")


File.open("GeneratedEvent.swift", "w") do |f| 
    f.write(
    """
struct GeneratedEvent: Loggable {
    public let eventName: String
    public let parameters: [String : Any]
    
    public init(eventName: String, parameters: [String : Any]) {
        self.eventName = eventName
        self.parameters = parameters
    }
}

extension GeneratedEvent {
    """
    )
    interfaceStatement.each do |s|
        f.write(s)
    end
    f.write(
        """
}
    """)

    f.write(
    """
extension LoggerBundler {
    func send(_ event: GeneratedEvent, with option: LoggingOption = .init()) async {
        await send(event as Loggable, with: option)
    }
}
    """
    )
    f.close
end
