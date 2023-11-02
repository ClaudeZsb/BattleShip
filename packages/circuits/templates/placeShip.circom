pragma circom 2.0.3;

include "../../../node_modules/circomlib/circuits/mux1.circom";
include "../../../node_modules/circomlib/circuits/multiplexer.circom";
include "../../../node_modules/circomlib/circuits/bitify.circom";

template PowerOf2(max) {
    assert(max < 253);
    signal input in;
    signal output out;

    component decoder = Decoder(max + 1);
    decoder.inp <== in;
    decoder.success === 1;

    component b2n = Bits2Num(max + 1);
    b2n.in <== decoder.out;
    out <== b2n.out;
}

/*
    Place a ship on a board while ensuring no collisions
    Input bits2num'd start board state, output bits2num'd end board state
    Expects previous safety checks and will not perform them here for resource preservation
    @param n - the length of the ship
*/
template PlaceShip(n) {
    signal input boardIn; // numerical representation of board bitmap before ship placement
    signal input ship[3]; // x, y, z of ships
    signal output boardOut; // numerical representation of board bitmap after ship placement
    
    /// INITIALIZE CONSTRUCTS ///
    component toBits = Num2Bits(100); // turns numerical board to bitmap
    toBits.in <== boardIn; // get board bitmap
    // initialize board placements
    signal boardH[10][10];
    signal boardV[10][10];
    for (var i = 0; i < 100; i++) {
        boardV[i \ 10][i % 10] <== toBits.out[i];
        boardH[i % 10][i \ 10] <== toBits.out[i];
    }
    // initialize expected collision num
    component expectedCollision = Bits2Num(n);
    for (var i = 0; i < n; i++) {
        expectedCollision.in[i] <== 1;
    }
    // initialize power of 2 and calculate ship value
    component powerX = PowerOf2(9);
    component powerY = PowerOf2(9);
    powerX.in <== ship[0];
    var powX = powerX.out;
    powerY.in <== ship[1];
    var powY = powerY.out;
    component power10X = PowerOf2(90);
    power10X.in <== ship[0] * 10;
    var powXY = power10X.out * powY;
    signal shipValueH <== ((2 ** n) - 1) * powXY;
    signal shipValueV <== n * powXY + n * (n - 1) / 2;

    /// HORIZONTAL PLACEMENT COLLISION CHECK ///
    // 1. use Multiplexer find the ith line
    component muxH = Multiplexer(10,10);
    muxH.inp <== boardH;
    muxH.sel <== ship[1];
    signal lineH[10] <== muxH.out;
    // 2. represent ship in binary array
    component n2bH = Num2Bits(10);
    n2bH.in <== powX * ((2 ** n) - 1);
    signal shipH[10] <== n2bH.out;
    // 3. calculate escalar product of ith line and ship binary
    component eproductH = EscalarProduct(10);
    eproductH.in1 <== lineH;
    eproductH.in2 <== shipH;
    var checkResultH = eproductH.out;
    // 4. update board
    var boardOutH = shipValueH + boardIn;

    /// VERTICAL PLACEMENT COLLISION CHECK ///
    // 1. use Multiplexer find the ith line
    component muxV = Multiplexer(10,10);
    muxV.inp <== boardV;
    muxV.sel <== ship[0];
    signal lineV[10] <== muxV.out;
    // 2. represent ship in binary array
    component n2bV = Num2Bits(10);
    n2bV.in <== powY * ((2 ** n) - 1);
    signal shipV[10] <== n2bV.out;
    // 3. calculate escalar product of ith line and ship binary
    component eproductV = EscalarProduct(10);
    eproductV.in1 <== lineV;
    eproductV.in2 <== shipV;
    var checkResultV = eproductV.out;
    // 4. update board
    var boardOutV = shipValueV + boardIn;

    /// CHOOSE COLLISION CHECK RESULT ///
    ship[2] * (1 - ship[2]) === 0; // z coordinate as selector for horizontal/ vertical
    (checkResultV - checkResultH) * ship[2] + checkResultH === 0; // expect 0 if no collisions

    /// CHOOSE AND OUTPUT NEXT BOARD STATE ///
    boardOut <== boardOutH + ship[2] * (boardOutH - boardOutV);
}