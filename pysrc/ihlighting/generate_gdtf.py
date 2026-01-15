import typing as t
import xml.etree.ElementTree as ET
from pathlib import Path
from xml.dom import minidom


def create_dmx_channel(offset, highlight, geometry, led_num, attribute):
    """Create a DMX channel element with its logical channel and channel function."""
    channel = ET.Element("DMXChannel")
    channel.set("DMXBreak", "1")
    channel.set("Offset", str(offset) if offset != "" else "")
    channel.set("Highlight", highlight)
    channel.set("Geometry", geometry)
    channel.set("InitialFunction", f"{geometry}_{attribute}.{attribute}.{attribute} 1")

    # Create LogicalChannel
    logical = ET.SubElement(channel, "LogicalChannel")
    logical.set("Attribute", attribute)
    logical.set("Snap", "No")
    logical.set("Master", "Grand" if attribute == "Dimmer" else "None")
    logical.set("MibFade", "0.000000")
    logical.set("DMXChangeTimeLimit", "0.000000")

    # Create ChannelFunction
    func = ET.SubElement(logical, "ChannelFunction")
    func.set("Name", f"{attribute} 1")

    if attribute == "Dimmer":
        func.set("Default", "0/4")
        func.set("DMXFrom", "0/4")
        dmx_values = ["0/4", "1/4", "4294967295/4"]
        names = ["Min", "", "Max"]
    else:
        func.set("Default", "255/1")
        func.set("DMXFrom", "0/1")
        dmx_values = ["0/1", "1/1", "255/1"]
        names = ["Min", "", "Max"]

    func.set("PhysicalFrom", "0.000000")
    func.set("PhysicalTo", "1.000000")
    func.set("RealFade", "0.000000")
    func.set("RealAcceleration", "0.000000")
    func.set("Min", "0.000000")
    func.set("Max", "0.000000")
    func.set("CustomName", "")
    func.set("OriginalAttribute", "")
    func.set("Attribute", attribute)

    # Create ChannelSets
    for name, dmx in zip(names, dmx_values):
        channel_set = ET.SubElement(func, "ChannelSet")
        channel_set.set("Name", name)
        channel_set.set("DMXFrom", dmx)
        channel_set.set("WheelSlotIndex", "0")

    return channel


def generate_gdtf_xml(num_leds=2, factor=1):
    """Generate GDTF DMXModes XML structure."""
    root = ET.Element("DMXModes")

    mode = ET.SubElement(root, "DMXMode")
    mode.set("Name", f"{num_leds} LEDs")
    mode.set("Description", "")
    mode.set("Geometry", "Base")

    channels = ET.SubElement(mode, "DMXChannels")
    relations = ET.SubElement(mode, "Relations")

    # Generate channels for each LED
    offset = 1
    for led_num in range(1, num_leds + 1):
        led_num = led_num * factor
        geometry = f"LED{led_num}"

        # Dimmer channel (no offset for first occurrence)
        channels.append(create_dmx_channel("", "4294967295/4", geometry, led_num, "Dimmer"))

        # RGB channels
        for color in ["ColorAdd_R", "ColorAdd_G", "ColorAdd_B"]:
            channels.append(create_dmx_channel(offset, "255/1", geometry, led_num, color))
            offset += 1

        # Create Relations
        for color in ["ColorAdd_R", "ColorAdd_G", "ColorAdd_B"]:
            relation = ET.SubElement(relations, "Relation")
            relation.set("Name", f"LED{led_num}_Dimmer over {color} 1")
            relation.set("Master", f"LED{led_num}_Dimmer")
            relation.set("Follower", f"LED{led_num}_{color}.{color}.{color} 1")
            relation.set("Type", "Multiply")

    # Create empty FTMacros
    ET.SubElement(mode, "FTMacros")

    return root


def prettify_xml(elem):
    """Return a pretty-printed XML string."""
    rough_string = ET.tostring(elem, encoding="unicode")
    reparsed = minidom.parseString(rough_string)
    return reparsed.toprettyxml(indent="    ")


if __name__ == "__main__":
    xml_root = generate_gdtf_xml(num_leds=40, factor=2)
    out_str = prettify_xml(xml_root)
    out_file = Path.home() / "Desktop" / "gdtf_dmxmode.xml"
    out_file.write_text(out_str, encoding="utf-8")
