import XCTest
@testable import PoScreenCast

final class PoScreenCastTests: XCTestCase {
    func testControlURLResolvesRelativePathWithoutPort() throws {
        let device = CastDevice(
            usn: "uuid:device-1::upnp:rootdevice",
            location: try XCTUnwrap(URL(string: "http://192.168.1.2/desc.xml")),
            dictionary: [
                "UDN": "uuid:device-1",
                "avTransport": [
                    "serviceType": SSDPSearchTarget.avTransport.rawValue,
                    "controlURL": "/upnp/control/AVTransport"
                ]
            ]
        )

        XCTAssertEqual(device.controlURL(for: .avTransport), "http://192.168.1.2/upnp/control/AVTransport")
    }

    func testControlURLUsesAbsoluteServiceURL() throws {
        let device = CastDevice(
            usn: "uuid:device-1::upnp:rootdevice",
            location: try XCTUnwrap(URL(string: "http://192.168.1.2:8000/desc.xml")),
            dictionary: [
                "UDN": "uuid:device-1",
                "avTransport": [
                    "serviceType": SSDPSearchTarget.avTransport.rawValue,
                    "controlURL": "http://192.168.1.3:9000/control"
                ]
            ]
        )

        XCTAssertEqual(device.controlURL(for: .avTransport), "http://192.168.1.3:9000/control")
    }

    func testDeviceParserKeepsURLBaseAndServices() throws {
        let xml = """
        <?xml version="1.0"?>
        <root xmlns="urn:schemas-upnp-org:device-1-0">
            <URLBase>http://192.168.1.2:8000/base/</URLBase>
            <device>
                <friendlyName>Living Room TV</friendlyName>
                <UDN>uuid:device-1</UDN>
                <serviceList>
                    <service>
                        <serviceType>urn:schemas-upnp-org:service:AVTransport:1</serviceType>
                        <serviceId>urn:upnp-org:serviceId:AVTransport</serviceId>
                        <controlURL>AVTransport/control</controlURL>
                    </service>
                </serviceList>
            </device>
        </root>
        """

        let result = try CastDeviceParser.parse(Data(xml.utf8))
        XCTAssertEqual(result["URLBase"] as? String, "http://192.168.1.2:8000/base/")
        XCTAssertEqual(result["friendlyName"] as? String, "Living Room TV")
        XCTAssertEqual((result["avTransport"] as? [String: String])?["controlURL"], "AVTransport/control")
    }

    func testSCPDParserFindsVolumeRangePrecisely() throws {
        let xml = """
        <?xml version="1.0"?>
        <scpd xmlns="urn:schemas-upnp-org:service-1-0">
            <serviceStateTable>
                <stateVariable sendEvents="no">
                    <name>A_ARG_TYPE_Channel</name>
                    <dataType>string</dataType>
                </stateVariable>
                <stateVariable sendEvents="yes">
                    <name>Volume</name>
                    <dataType>ui2</dataType>
                    <allowedValueRange>
                        <minimum>0</minimum>
                        <maximum>100</maximum>
                        <step>1</step>
                    </allowedValueRange>
                </stateVariable>
            </serviceStateTable>
        </scpd>
        """

        let result = try SCPDParser.parse(Data(xml.utf8))
        XCTAssertEqual(result["minimum"], "0")
        XCTAssertEqual(result["maximum"], "100")
        XCTAssertEqual(result["step"], "1")
    }

    func testSOAPParsersIgnoreNamespacePrefixes() throws {
        let volumeXML = """
        <?xml version="1.0"?>
        <SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">
            <SOAP-ENV:Body>
                <m:GetVolumeResponse xmlns:m="urn:schemas-upnp-org:service:RenderingControl:1">
                    <CurrentVolume>35</CurrentVolume>
                </m:GetVolumeResponse>
            </SOAP-ENV:Body>
        </SOAP-ENV:Envelope>
        """
        let volumeResponse = CastActionResponse(action: CastAction(type: .getVolume), rawData: Data(volumeXML.utf8), failure: nil)
        XCTAssertEqual(try volumeResponse.parseToVolume().value, 35)

        let transportXML = """
        <?xml version="1.0"?>
        <e:Envelope xmlns:e="http://schemas.xmlsoap.org/soap/envelope/">
            <e:Body>
                <u:GetTransportInfoResponse xmlns:u="urn:schemas-upnp-org:service:AVTransport:1">
                    <CurrentTransportState>PLAYING</CurrentTransportState>
                    <CurrentTransportStatus>OK</CurrentTransportStatus>
                    <CurrentSpeed>1</CurrentSpeed>
                </u:GetTransportInfoResponse>
            </e:Body>
        </e:Envelope>
        """
        let transportResponse = CastActionResponse(action: CastAction(type: .getTransportInfo), rawData: Data(transportXML.utf8), failure: nil)
        let transportInfo = try transportResponse.parseToTransportInfo()
        XCTAssertEqual(transportInfo.currentTransportState, .playing)
        XCTAssertEqual(transportInfo.currentTransportStatus, .ok)
        XCTAssertEqual(transportInfo.currentSpeed, "1")
    }

    func testSetAVTransportURIMetadataEscapesNestedDIDL() {
        let action = CastAction(type: .setAVTransportURI(uri: "http://example.com/video.mp4?x=1&y=2", videoName: "A&B"))

        XCTAssertTrue(action.xmlString.contains("A&amp;amp;B"))
        XCTAssertTrue(action.xmlString.contains("http://example.com/video.mp4?x=1&amp;amp;y=2"))
        XCTAssertTrue(action.xmlString.contains("video/mp4"))
    }
}
