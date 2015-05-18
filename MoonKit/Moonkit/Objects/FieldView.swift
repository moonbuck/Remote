//
//  FieldView.swift
//  MoonKit
//
//  Created by Jason Cardwell on 5/11/15.
//  Copyright (c) 2015 Jason Cardwell. All rights reserved.
//

import Foundation

public enum FieldTemplate {
  case Text     (value: String, placeholder: String?, validation: ((String?) -> Bool)?)
  case Switch   (value: Bool)
  case Slider   (value: Float, min: Float, max: Float)
  case Stepper  (value: Double, min: Double, max: Double, step: Double)
  case Picker   (value: Int, choices: [String])
  case Checkbox (value: Bool)
}

public class Field: NSObject {
  public enum Type { case Undefined, Text, Switch, Slider, Stepper, Picker, Checkbox }

  var control: UIView { return UIView() }
  public var value: Any?
  public var valid: Bool { return true }
  public var type: Type { return .Undefined }
  public var changeHandler: ((Field) -> Void)?

  func valueDidChange(sender: AnyObject) { changeHandler?(self) }

  public static func fieldWithTemplate(template: FieldTemplate) -> Field {
    switch template {
    case let .Text(value, placeholder, validation):
      return TextField(value: value, placeholder: placeholder, validation: validation)
    case let .Switch(value):
      return SwitchField(value: value)
    case let .Slider(value, min, max):
      return SliderField(value: value, min: min, max: max)
    case let .Stepper(value, min, max, step):
      return StepperField(value: value, min: min, max: max, step: step)
    case let .Picker(value, choices):
      return PickerField(value: value, choices: choices)
    case let .Checkbox(value):
      return CheckboxField(value: value)
    }
  }

  private final class TextField: Field, UITextFieldDelegate {
    var _value: String = ""
    override var type: Type { return .Text }
    override var value: Any? { get { return _value } set { if let v = newValue as? String { _value = v } } }
    override var valid: Bool { return validation?(_value) ?? true }
    var placeholder: String?
    var validation: ((String?) -> Bool)?

    init(value: String, placeholder: String?, validation: ((String?) -> Bool)?) {
      _value = value; self.placeholder = placeholder; self.validation = validation; super.init()
    }

    weak var _control: UITextField?
    override var control: UIView {
      let control = UITextField.newForAutolayout()
      control.textAlignment = .Right
      control.returnKeyType = .Done
      control.layer.shadowColor = UIColor.redColor().CGColor
      control.delegate = self
      control.addTarget(self, action: "valueDidChange:", forControlEvents: .ValueChanged)
      control.text = _value
      control.placeholder = placeholder
      _control = control
      return control
    }
    @objc func textFieldShouldReturn(textField: UITextField) -> Bool {
      textField.resignFirstResponder()
      return false
    }
  }

  private final class SwitchField: Field {
    var _value = false
    override var type: Type { return .Switch }
    override var value: Any? { get { return _value } set { if let v = newValue as? Bool { _value = v } } }
    init(value: Bool) { _value = value; super.init()  }
    weak var _control: UISwitch?
    override var control: UIView {
      let control = UISwitch.newForAutolayout()
      control.addTarget(self, action: "valueDidChange:", forControlEvents: .ValueChanged)
      control.on = _value
      _control = control
      return control
    }
  }

  private final class SliderField: Field {
    var _value: Float = 0
    override var type: Type { return .Slider }
    override var value: Any? { get { return _value } set { if let v = newValue as? Float { _value = v } } }
    var min: Float = 0
    var max: Float = 1
    init(value: Float, min: Float, max: Float) {
      _value = value; self.min = min; self.max = max; super.init()
    }
    weak var _control: UISlider?
    override var control: UIView {
      let control = UISlider.newForAutolayout()
      control.value = _value
      control.addTarget(self, action: "valueDidChange:", forControlEvents: .ValueChanged)
      _control = control
      return control
    }
  }

  private final class StepperField: Field {
    var _value = 0.0
    override var type: Type { return .Stepper }
    override var value: Any? { get { return _value } set { if let v = newValue as? Double { _value = v } } }
    var min = 0.0
    var max = 100.0
    var step = 1.0

    init(value: Double, min: Double, max: Double, step: Double) {
      _value = value; self.min = min; self.max = max; self.step = step; super.init()
    }
    weak var _control: UIStepper?
    override var control: UIView {
      let control = UIStepper.newForAutolayout()
      control.value = _value
      control.addTarget(self, action: "valueDidChange:", forControlEvents: .ValueChanged)
      _control = control
      return control
    }
  }

  private final class PickerField: Field, AKPickerViewDelegate, AKPickerViewDataSource {
    var _value = 0
    override var type: Type { return .Picker }
    override var value: Any? { get { return _value } set { if let v = newValue as? Int { _value = v } } }
    var choices: [String] = []

    init(value: Int, choices: [String]) {
      _value = value; self.choices = choices; super.init()
    }

    weak var _control: AKPickerView?
    override var control: UIView {
      let control = AKPickerView.newForAutolayout()
      control.delegate = self
      control.dataSource = self
      control.selectItem(_value)
      control.interitemSpacing = 20.0
      _control = control
      return control
    }

    @objc func numberOfItemsInPickerView(pickerView: AKPickerView) -> Int {
      return choices.count
    }

    @objc func pickerView(pickerView: AKPickerView, titleForItem item: Int) -> String {
      return choices[item]
    }

    @objc func pickerView(pickerView: AKPickerView, didSelectItem item: Int) {
      _value = item
      valueDidChange(self)
    }
  }

  private final class CheckboxField: Field {
    var _value = false
    override var type: Type { return .Checkbox }
    override var value: Any? { get { return _value } set { if let v = newValue as? Bool { _value = v } } }

    init(value: Bool) { _value = value; super.init() }

    weak var _control: Checkbox?
    override var control: UIView {
      let control = Checkbox.newForAutolayout()
      control.checked = _value
      control.addTarget(self, action: "valueDidChange:", forControlEvents: .ValueChanged)
      _control = control
      return control
    }
  }

}


/** View subclass for a single form field with a name label and a control for capturing the value */
final class FieldView: UIView {

  // MARK: - Field-related properties

  let name: String
  let field: Field
  var value: Any? { get { return field.value } set { field.value = newValue } }

  // MARK: - Customizing appearance

  var labelFont: UIFont { get { return nameLabel.font } set { nameLabel.font = newValue } }
  var labelTextColor: UIColor { get { return nameLabel.textColor } set { nameLabel.textColor = newValue } }

  var controlFont: UIFont? {
    get { return textControl?.font ?? pickerControl?.font }
    set { if let font = newValue { textControl?.font = font; pickerControl?.font = font } }
  }
  var controlSelectedFont: UIFont? {
    get { return pickerControl?.highlightedFont }
    set { if let font = newValue { pickerControl?.highlightedFont = font } }
  }
  var controlTextColor: UIColor? {
    get { return textControl?.textColor ?? pickerControl?.textColor }
    set { if let color = newValue { textControl?.textColor = color;  pickerControl?.textColor = color } }
  }
  var controlSelectedTextColor: UIColor? {
    get { return  pickerControl?.highlightedTextColor }
    set { if let color = newValue { pickerControl?.highlightedTextColor = color } }
  }

  // MARK: - Label and control

  /** Overridden to return the field view's `name` property */
  override var nametag: String! { get { return nameLabel.text } set {} }

  weak var nameLabel: UILabel!
  weak var fieldControl: UIView!

  var didChangeValue: ((FieldView) -> Void)?

  var textControl: UITextField?    { return fieldControl as? UITextField  }
  var switchControl: UISwitch?     { return fieldControl as? UISwitch     }
  var sliderControl: UISlider?     { return fieldControl as? UISlider     }
  var stepperControl: UIStepper?   { return fieldControl as? UIStepper    }
  var pickerControl: AKPickerView? { return fieldControl as? AKPickerView }
  var checkboxControl: Checkbox?   { return fieldControl as? Checkbox     }

  // MARK: Observing value changes

  /**
  valueDidChange:

  :param: sender UIControl
  */
  func valueDidChange(sender: UIControl) {
    MSLogDebug("sender = \(toString(sender))")
  }

  // MARK: Validating text fields

  var valid: Bool { return field.valid }
  var showingInvalid = false { didSet { textControl?.layer.shadowOpacity = showingInvalid ? 0.9 : 0.0 } }

  // MARK: - Initializing the view

  /** initializeIVARs */
  private func initializeIVARs() {
    setTranslatesAutoresizingMaskIntoConstraints(false)
    let label = UILabel.newForAutolayout()
    label.text = name
    addSubview(label)
    nameLabel = label
    let control = field.control
    addSubview(control)
    fieldControl = control
  }

  /**
  Initialize the view with a name and field

  :param: n String
  :param: f Field
  */
  init(tag t: Int, name n: String, field f: Field) {
    name = n; field = f
    super.init(frame: CGRect.zeroRect)
    tag = t
    initializeIVARs()
  }

  required init(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  // MARK: - Constraints

  override class func requiresConstraintBasedLayout() -> Bool { return true }

  /**
  intrinsicContentSize

  :returns: CGSize
  */
  override func intrinsicContentSize() -> CGSize {
    let labelSize = nameLabel.intrinsicContentSize()
    let fieldSize = fieldControl.intrinsicContentSize()
    return CGSize(width: labelSize.width + 10.0 + fieldSize.width,
                  height: max(labelSize.height, fieldSize.height))
  }

  override func updateConstraints() {
    super.updateConstraints()
    let id = createIdentifier(self, "Internal")
    removeConstraintsWithIdentifier(id)
    constrain([𝗩|nameLabel|𝗩, 𝗩|fieldControl|𝗩] --> id)
    constrain([𝗛|nameLabel, fieldControl.left => nameLabel.right + 10.0, fieldControl|𝗛] --> id)
  }

}
