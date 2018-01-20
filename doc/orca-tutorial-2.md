![ORCA logo](orca_small.png)

# Naïve approaches and decomposition methods in orca

This tutorial will cover how to apply naïve approaches and decomposition methods in the framework ORCA. It is highly recommended to have previously completed the [how to tutorial](orca-tutorial.md).

We are going to test these methods using a melanoma diagnosis dataset based on dermatoscopic images. Melanoma is a type of cancer that develops from the pigment-containing cells known as melanocytes. Usually occurring on the skin, early detection and diagnosis is strongly related to survival rates. The dataset is aimed at predicting the severity of the lesion:
- A total of `100` image descriptors are used as input features, including features related to shape, colour, pigment network and texture.
- The severity is assessed in terms of melanoma thickness, measured by the Breslow index. The problem is tackled as a five-class classification problem, where the first class represents benign lesions, and the remaining four classes represent the different stages of the melanoma (0, I, II and III, where III is the thickest one and the most dangerous).

The dataset is included in this repository, in a specific [folder](/exampledata/10-fold/melanoma-5classes-abcd-100/matlab).
