import Dialectic.Language

/-!
Lean language-server regression input. Running this file with
`Lean.Server.Test.Runner` requests the stock editor code action at the draft
marker and exposes the versioned text edit in the response.
-/

Argument SocraticInquiryDraft

Logic profile CoreLogic
  Description "a bounded draft inspired by a Socratic chain of classification"
End logic

Vocabulary
  Type Inquiry called inquiry
  Predicate examined describes Inquiry
  Predicate reflective describes Inquiry
  Predicate selfCorrecting describes Inquiry
End vocabulary

Source SocraticInquiry
  Citation "Original reconstruction inspired by Socratic examination; no sentence is a quotation"
  Location "a bounded methodological argument"
  Sentence 1 "Every examined inquiry is reflective."
  Sentence 2 "Every reflective inquiry is self-correcting."
  Sentence 3 "Every examined inquiry is self-correcting."
End source

Reconstruction Original
  Claim P1 from SocraticInquiry sentence 1
    Paraphrase "Every examined inquiry is reflective."
    Formal meaning Every examined inquiry is reflective
  End claim

  Claim P2 from SocraticInquiry sentence 2
    Paraphrase "Every reflective inquiry is self-correcting."
    Formal meaning Every reflective inquiry is selfCorrecting
  End claim

  Claim Conclusion from SocraticInquiry sentence 3
    Paraphrase "Every examined inquiry is self-correcting."
    Formal meaning Every examined inquiry is selfCorrecting
  End claim

  Deduction Examination
    Goal Conclusion
    Continue deduction
    --^ codeAction
  End deduction
End reconstruction

Alternative RestrictedReflection based on Original
  Change P1
    Original meaning Every examined inquiry is reflective
    Alternative meaning Some examined inquiry is reflective
  End change
  Recheck the same deduction Examination
End alternative

End argument
