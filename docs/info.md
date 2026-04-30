<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works
TINY_NN implements a small two-layer fully-connected neural network in hardware to classify whether a 4-bit (x, y) coordinate lies inside or outside a circle.

Network architecture: The network has two layers. Layer 0 is a 2-input, 6-neuron linear layer. Its outputs pass through a ReLU activation. Layer 1 is a 6-input, 1-neuron linear layer. All weights and biases are hardcoded. The final output bit is the sign of the single layer-1 output node.

Fixed-point arithmetic: All arithmetic uses 4-bit signed fixed-point values. The mul module performs saturating multiply-accumulate: products are scaled by right-shifting 2 bits. All computation overflow is clamped to min/max values, keeping all intermediate values in range without needing wider datapaths.

Control flow: A 6-state FSM sequences the computation (idle, layer0, layer1, etc), orchestrating the inputs and outputs of each layer and asserting done once everything is completed.

## How to test

Reset: Hold btn[3] to reset all registers and the FSM (active low).
Load X coordinate: Set your 4-bit X value on the switches, then pulse btn[1] high.
Load Y coordinate: Set your 4-bit Y value on the switches, then pulse btn[0] high.
Run inference: Pulse btn[2] to start the inference. The FSM will sequence through both MAC layers automatically.
Read result: Once valid goes high, read inside_circle (both on the LED). A 1 means the point is classified as inside the circle; a 0 means outside.

To run another inference, assert rst_n (btn[3]). 

## External hardware
4 switches — sets the 4-bit coordinate value before each load
4 push buttons — connected to btn[3:0]: rst_n (btn[3]), start (btn[2]), load X (btn[1]), load Y (btn[0])
2 LEDs — one for valid (inference complete) and one for inside_circle (classification result)
