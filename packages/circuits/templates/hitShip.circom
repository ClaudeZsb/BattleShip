pragma circom 2.0.3;

include "../node_modules/circomlib/circuits/comparators.circom";

/*
    Determine whether or not a given ship uses a given x/y coordinate pair
    @param n - the length of the ship
*/
template HitShip(n) {

    signal input ship[3]; // x, y, z to hitscan from
    signal input shot[2]; // x, y, to hitscan with
    signal output hit; // 0 if not hit, 1 if hit

    /// HORIZONTAL CONSTRAINT ///
    component hYEq = IsEqual();
    hYEq.in[0] <== shot[1];
    hYEq.in[1] <== ship[1];
    component hXLeft = GreaterEqThan(4);
    hXLeft.in[0] <== shot[0];
    hXLeft.in[1] <== ship[0];
    component hXRight = LessThan(4);
    hXRight.in[0] <== shot[0];
    hXRight.in[1] <== ship[0] + n;
    signal hX <== hXLeft.out * hXRight.out;
    signal hHit <== hX * hYEq.out;

    /// VERTICAL CONSTRAINT ///
    component vXEq = IsEqual();
    vXEq.in[0] <== shot[0];
    vXEq.in[1] <== ship[0];
    component vYDown = GreaterEqThan(4);
    vYDown.in[0] <== shot[1];
    vYDown.in[1] <== ship[1];
    component vYUp = LessThan(4);
    vYUp.in[0] <== shot[1];
    vYUp.in[1] <== ship[1] + n;
    signal vY <== vYDown.out * vYUp.out;
    signal vHit <== vY * vXEq.out;

    /// CHOOSE OUTPUT ///
    hit <== hHit + (vHit - hHit) * ship[2];
}