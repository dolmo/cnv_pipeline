Metric	Meaning
TP-base	Truth variants that Manta correctly called (True Positives, from truth)
TP-call	Manta calls that matched a truth variant (True Positives, from calls)
FN	Truth variants that Manta missed (False Negatives)
FP	Manta calls that didn’t match any truth (False Positives)
Precision	TP-call / (TP-call + FP) – How many of your calls were correct
Recall	TP-base / (TP-base + FN) – How many true variants you caught
F1 Score	Harmonic mean of precision and recall