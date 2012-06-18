
require 'ffi'

class Skype
  module Communication
    class Windows
      # This module is used to provide access to the Win32 API to Ruby. There is lots of stuff here that is poorly named
      # but tries stick closely to the original Win32 API for ease of reference.
      #
      # BEWARE: Here there be dragons aplenty.
      module Win32
        extend FFI::Library
        ffi_lib('user32', 'kernel32')
        ffi_convention(:stdcall)

        private

        def self._func(*args)
          attach_function *args
          case args.size
            when 3
              module_function args[0]
            when 4
              module_function args[0]
              alias_method(args[1], args[0])
              module_function args[1]
          end
        end

        public

        ULONG_PTR = FFI::TypeDefs[:ulong]
        LONG_PTR = FFI::TypeDefs[:long]

        ULONG = FFI::TypeDefs[:ulong]
        LONG = FFI::TypeDefs[:long]
        LPVOID = FFI::TypeDefs[:pointer]
        INT = FFI::TypeDefs[:int]
        BYTE = FFI::TypeDefs[:uint16]
        DWORD = FFI::TypeDefs[:ulong]
        BOOL = FFI::TypeDefs[:int]
        UINT = FFI::TypeDefs[:uint]
        POINTER = FFI::TypeDefs[:pointer]
        VOID = FFI::TypeDefs[:void]

        HWND = HICON = HCURSOR = HBRUSH = HINSTANCE = HGDIOBJ =
            HMENU = HMODULE = HANDLE = ULONG_PTR
        LPARAM = LONG_PTR
        WPARAM = ULONG_PTR
        LPCTSTR = LPMSG = LPVOID
        LRESULT = LONG_PTR
        ATOM = BYTE
        NULL = 0

        # This is the callback function used to process window messages.
        WNDPROC = callback(:WindowProc, [HWND, UINT, WPARAM, LPARAM], LRESULT)

        # @todo Document this better
        # @see http://msdn.microsoft.com/en-us/library/windows/desktop/ms633577.aspx MSDN
        class WNDCLASSEX < FFI::Struct
          layout :cbSize, UINT,
                 :style, UINT,
                 :lpfnWndProc, WNDPROC,
                 :cbClsExtra, INT,
                 :cbWndExtra, INT,
                 :hInstance, HANDLE,
                 :hIcon, HICON,
                 :hCursor, HCURSOR,
                 :hbrBackground, HBRUSH,
                 :lpszMenuName, LPCTSTR,
                 :lpszClassName, LPCTSTR,
                 :hIconSm, HICON

          def initialize(*args)
            super
            self[:cbSize] = self.size
            @atom = 0
          end

          def register_class_ex
            (@atom = Win32::RegisterClassEx(self)) != 0 ? @atom : raise("RegisterClassEx Error")
          end

          def atom
            @atom != 0 ? @atom : register_class_ex
          end
        end # WNDCLASSEX

        class POINT < FFI::Struct
          layout :x, LONG,
                 :y, LONG
        end

        class MSG < FFI::Struct
          layout :hwnd, HWND,
                 :message, UINT,
                 :wParam, WPARAM,
                 :lParam, LPARAM,
                 :time, DWORD,
                 :pt, POINT
        end

        # @!method RegisterWindowMessage(message_name)
        #
        # Registers a Window Message with Windows or returns a handle to an existing message.
        #
        # @param [String] message_name The name of the message to register
        # @return [Handle]
        # @see http://msdn.microsoft.com/en-us/library/windows/desktop/ms644947.aspx MSDN
        _func(:RegisterWindowMessage, :RegisterWindowMessageA, [LPCTSTR], UINT)

        # @!method GetModuleHandle(module_name)
        #
        # Used to obtain a handle to a module loaded by the application. If passed DL::NULL then returns a
        # handle to the current module.
        #
        # @param [String|DL::NULL] module_name The name of the module to return a handle to.
        # @return [ModuleHandle]
        # @see http://msdn.microsoft.com/en-us/library/windows/desktop/ms683199.aspx MSDN
        _func(:GetModuleHandle, :GetModuleHandleA, [LPCTSTR], HMODULE)

        # @!method RegisterClassEx(class_definition)
        #
        # Registers a Window Class for use with CreateWindowEx.
        #
        # @param [WindowClass] class_definition
        # @return [Handle]
        # @see http://msdn.microsoft.com/en-us/library/windows/desktop/ms633587.aspx MSDN
        _func(:RegisterClassEx, :RegisterClassExA, [LPVOID], ATOM)

        # @!method CreateWindowEx(extended_style, window_class, window_name, style, x, y, width, height, parent, menu, instance)
        #
        # Creates a new window.
        #
        # @param [Integer] extended_style A combination of WS_EX_* constant values defining the extended style for this window.
        # @param [String] window_class This matches up with a registered WindowClass's lpszClassName parameter.
        # @param [String] window_name This is the title of the newly created window.
        # @param [Integer] style A combination of the WS_* constant values defining the style for this window.
        # @param [Integer] x The horizontal position of the window on the screen.
        # @param [Integer] y The vertical position of the window on the screen.
        # @param [Integer] width The width of the window to create.
        # @param [Integer] height The height of the window to create.
        # @param [WindowHandle] parent A parent window for this one.
        # @param [MenuHandle] menu The menu for this window.
        # @param [InstanceHandle] instance
        # @return [WindowHandle]
        # @see http://msdn.microsoft.com/en-us/library/windows/desktop/ms632680.aspx MSDN
        _func(:CreateWindowEx, :CreateWindowExA, [DWORD, LPCTSTR, LPCTSTR, DWORD, INT, INT, INT, INT, HWND, HMENU, HINSTANCE, LPVOID], HWND)
        _func(:GetMessage, :GetMessageA, [LPMSG, HWND, UINT, UINT], BOOL)
        _func(:TranslateMessage, [LPVOID], BOOL)
        _func(:DispatchMessage, :DispatchMessageA, [LPVOID], BOOL)
        _func(:DefWindowProc, :DefWindowProcA, [HWND, UINT, WPARAM, LPARAM], LRESULT)

        # @!group Predefined WindowHandle's
        #
        # These are WindowHandle's provided by the Win32 API for special purposes.

        # Target for SendMessage(). Broadcast to all windows.
        HWND_BROADCAST = 0xffff
        # Used as a parent in CreateWindow(). Signifies that this should be a message-only window.
        HWND_MESSAGE = -3

        # @!endgroup

        # CreateWindow Use Default Value
        CW_USEDEFAULT = 0x80000000

        COLOR_WINDOW = 5
        COLOR_WINDOWFRAME = 6

        # @!group Class Style contants.

        CS_VREDRAW = 0x0001
        CS_HREDRAW = 0x0002

        # @!group Window Style constants
        #
        # This is only a subset.
        # @see http://msdn.microsoft.com/en-us/library/windows/desktop/ms632600.aspx

        WS_BORDER =      0x00800000
        WS_CAPTION =     0x00C00000
        WS_DISABLED =    0x08000000
        WS_OVERLAPPED =  0x00000000
        WS_POPUP =       0x80000000
        WS_SIZEBOX =     0x00040000
        WS_SYSMENU =     0x00080000
        WS_THICKFRAME =  0x00040000
        WS_MAXIMIZEBOX = 0x00010000
        WS_MINIMIZEBOX = 0x00020000
        WS_OVERLAPPEDWINDOW = WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX
        WS_POPUPWINDOW = WS_POPUP | WS_BORDER | WS_SYSMENU

        # @!group Window Extended Style constants
        #
        # This is only a subset.
        # @see http://msdn.microsoft.com/en-us/library/windows/desktop/ff700543.aspx

        WS_EX_LEFT = 0

        # @!endgroup
      end
    end
  end
end
