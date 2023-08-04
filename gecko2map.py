# This file will attempt to parse an input file for gecko codes and create an address map for Dolphin

import argparse
import os

# This is where the gecko codes are always injected
gc_start_address = 0x8065cc88

# Offset that tracks where the next gecko code needs to be inserted
offset = 0

# We track the last function name for binary codes that have
# lots of one-liner replacements instead of injections
last_function_name = ''

# Flag that indicates if we are currently processing an injection-type gecko code
# Used to track whether we should keep reading lines or just keep going
processing_code = False

# Tracks how many lines are left when processing a C2/06 gecko code
lines_to_process=0

# Function to parse a Gecko code block and generate a symbol map entry
def parse_gecko_code(gecko_code):
    global offset
    global processing_code
    global last_function_name
    global lines_to_process

    # Split the gecko code by spaces
    gecko_code_parts = gecko_code.split()

    # Parse the address, number of lines, and function name
    # This is not being used right now, but it holds the original address meant to be updated
    address = int(f'0x80{gecko_code_parts[0][2:]}', 16)
    code_lines = int(gecko_code_parts[1], 16)
    function_name = " ".join(gecko_code_parts[2:]).replace(' ', '_')

    # Set the same name of the previous function if this one is empty
    # This is useful for a bunch of 04 geko code types
    if len(function_name) == 0:
        function_name = last_function_name

    # Make sure to set the address at the current offset of the starting gecko code point
    address = gc_start_address + offset

    # Calculate the size of the code (in bytes)
    code_size = code_lines * 2 * 4

    if any(gecko_code.startswith(prefix) for prefix in ["C2","06"]):
        # If the code has more lines to read, flag the program as processing_code
        # and track the amount of lines to skip through
        processing_code = True
        lines_to_process = code_lines
        # add the size of the code as a byte offset
        offset += code_size
        # skip over the first line
        address += 0x8
    elif gecko_code.startswith("04"):
        code_size = 0x4 # fixed size

    # always sum up the bytes of the first line
    # for the global offset
    offset += 0x8

    # Track the function's name
    last_function_name = function_name

    # Print!
    symbol_map_entry = f'{address:08x} {code_size:08x} {address:08x} 0 {function_name}\n'
    return symbol_map_entry


def combine_maps(input_file_path, string_to_insert):
    with open(input_file_path, 'r') as input_file:
        content = input_file.read().splitlines()

    # Find the index where the ".data section layout" starts
    data_section_index = next((index for index, line in enumerate(content) if line.strip() == ".data section layout"), None)

    # If the data section is present, insert the given string before it
    # Otherwise, append the string to the end of the content
    if data_section_index is not None:
        # Check if the previous line is empty
        if content[data_section_index - 1].strip() == "":
            content[data_section_index - 1] = string_to_insert
        else:
            content.insert(data_section_index, string_to_insert)
    else:
        # Append the string to the content, ensuring no empty line before it
        if content[-1].strip() == "":
            content[-1] = string_to_insert
        else:
            content.append(string_to_insert)

    content.append("") # Ensure there is at least one empty line at the end

    return '\n'.join(content)

# Create the parser
parser = argparse.ArgumentParser(description='Generate a symbol map from a Gecko codes file.')

# Add the arguments
parser.add_argument('InputFile', metavar='input file', type=str, help='the input file containing Gecko codes',)
parser.add_argument('-o', '--output', default='./Output/Maps/GALE01r2.map', metavar='output filename', type=str, help='the output map file', required=False)
parser.add_argument('-c', '--combine', default=None, metavar='combine filename', type=str, help='combines the output of this process with other map file', required=False)

# Parse the arguments
args = parser.parse_args()

# Read the input text file
with open(args.InputFile, 'r') as f:
    lines = f.read().splitlines()

# Initialize an empty string to hold the symbol map
symbol_map = ''

# Parse each line in the text file
for line in lines:
    if lines_to_process > 0:
        lines_to_process -= 1
        processing_code = False
    else:
        # If the line starts with 'C2', parse it and add the symbol map entry to the symbol map
        starts_with_prefix = any(line.startswith(prefix) for prefix in ["C2","04","06"])
        if starts_with_prefix and not processing_code:
            symbol_map += parse_gecko_code(line)


# Create path if it doesn't exist
if not os.path.exists(os.path.dirname(args.output)):
    os.makedirs(os.path.dirname(args.output))

# combine files if there's an existing map file to merge with
if args.combine:
    symbol_map = combine_maps(args.combine, symbol_map)

# Write the symbol map to a file
with open(args.output, 'w') as f:
    f.write(symbol_map)

# print(symbol_map)  # Display the symbol map
