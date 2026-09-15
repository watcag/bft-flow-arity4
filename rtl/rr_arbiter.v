// Adapted from:
// https://web.archive.org/web/20190427040640/http://fpgacpu.ca/fpga/priority.html
// https://web.archive.org/web/20190427040424/http://fpgacpu.ca/fpga/thermometer.html
// https://web.archive.org/web/20190423002739/http://fpgacpu.ca/fpga/roundrobin.html

// Copyright (c) 2019 Charles Eric LaForest, PhD.
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and 
// associated documentation files (the "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject
// to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
// TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
// THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
// CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// Returns a single bit set from all set request bits, in a round-robin order
// going from LSB to MSB and back around. Requests can be added or dropped
// on-the-fly, but synchronously to the clk.

module rr_arbiter
#(
    parameter WORD_WIDTH                = 8
)
(
    input   wire                        clk,
    input   wire                        rst,
    input   wire    [WORD_WIDTH-1:0]    requests,
    output  wire    [WORD_WIDTH-1:0]    grant
);

    localparam zero = {WORD_WIDTH{1'b0}};

    reg [WORD_WIDTH-1:0] grant_reg;

// --------------------------------------------------------------------

    // Grant a request in priority order (LSB has higest priority)

    wire [WORD_WIDTH-1:0] grant_raw = requests & -requests;

// --------------------------------------------------------------------

    // Mask-off all requests of higher priority 
    // than the request granted in the previous cycle.

    reg [WORD_WIDTH-1:0] mask;

    always @(*) begin
        mask <= grant_reg ^ (grant_reg - 1);
        mask <= (grant_reg == zero) ? mask : ~mask;
        mask <= mask | grant_reg;
    end

    wire [WORD_WIDTH-1:0] requests_masked = requests & mask;

// --------------------------------------------------------------------

    // Grant a request in priority order, but from the masked requests
    // (equal or lower priority to the request granted last cycle)

    wire [WORD_WIDTH-1:0] grant_masked;

    assign grant_masked = requests_masked & -requests_masked;

// --------------------------------------------------------------------

    // If no granted requests remain after masking, then grant from the
    // unmasked requests, which starts over granting from the highest (LSB)
    // priority. This also rsts the mask. And the process begins again.

    assign grant = (grant_masked == zero) ? grant_raw : grant_masked;

    always @(posedge clk) begin
        if (rst) begin
            grant_reg <= zero;
        end else begin
            grant_reg <= grant; 
        end
    end

endmodule
