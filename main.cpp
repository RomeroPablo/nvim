// a compact survey of C++26 syntax and semantic tokens.

#include <algorithm>
#include <array>
#include <compare>
#include <concepts>
#include <cstddef>
#include <cstdint>
#include <iostream>
#include <optional>
#include <stdexcept>
#include <string>
#include <string_view>
#include <type_traits>
#include <utility>
#include <vector>

#define APP_VERSION "1.0.0"

namespace theme_preview {

constexpr std::size_t kDefaultWidth = 80;
constexpr double kGoldenRatio = 1.6180339887;

enum class LogLevel : std::uint8_t {
	debug,
	info,
	warning,
	error,
};

struct Color {
	std::uint8_t red = 0;
	std::uint8_t green = 0;
	std::uint8_t blue = 0;

	auto operator<=>(const Color&) const = default;

	[[nodiscard]] constexpr auto red_channel(this auto&& self) noexcept -> decltype(auto)
	{
		return (std::forward_like<decltype(self)>(self.red));
	}

	[[nodiscard]] constexpr auto luminance() const noexcept -> double
	{
		return 0.2126 * red + 0.7152 * green + 0.0722 * blue;
	}
};

template <typename T>
concept Numeric = std::is_arithmetic_v<T>;

template <typename T>
concept ColorLike = requires(const T& value) {
	{ value.luminance() } noexcept -> std::convertible_to<double>;
};

template <Numeric T>
[[nodiscard]] constexpr auto clamp(T value, T minimum, T maximum) -> T
{
	return std::min(std::max(value, minimum), maximum);
}

template <Numeric... Values>
[[nodiscard]] constexpr auto sum(Values... values)
{
	return (values + ...);
}

template <typename... Values>
	requires(sizeof...(Values) > 0)
[[nodiscard]] constexpr auto first(Values&&... values) -> decltype(auto)
{
	return (values...[0]);
}

template <typename Tuple>
[[nodiscard]] constexpr auto tail_size(const Tuple& tuple) -> std::size_t
{
	const auto [head, ...tail] = tuple;
	(void)head;
	return sizeof...(tail);
}

[[nodiscard]] constexpr auto contrast(int value) -> int
{
	if consteval {
		return value * value;
	} else {
		return value < 0 ? -value : value;
	}
}

[[nodiscard]] constexpr auto red_component(Color color) -> std::uint8_t
{
	const auto [red, _, _] = color;
	return red;
}

static_assert(ColorLike<Color>);
static_assert(sum(1, 2, 3) == 6, std::string_view { "fold expression failed" });
static_assert(first(4, 5, 6) == 4);
static_assert(tail_size(std::array { 1, 2, 3 }) == 2);
static_assert(contrast(4) == 16);
static_assert(red_component(Color { .red = 42 }) == 42);

using Palette = std::vector<Color>;

struct LookupResult {
	std::size_t index;
	bool found;

	explicit constexpr operator bool() const noexcept { return found; }
};

[[nodiscard]] auto legacy_palette() -> Palette = delete("use make_palette() instead");

/**
 * Small example type for fields, methods, constructors, and access specifiers.
 * Comments should remain secondary, but never difficult to read.
 */
class Renderer final {
public:
	explicit Renderer(std::string name, std::size_t width = kDefaultWidth)
		: name_(std::move(name)), width_(width)
	{
	}

	[[nodiscard]] auto name() const noexcept -> std::string_view { return name_; }

	auto set_accent(std::optional<Color> accent) -> void { accent_ = accent; }

	auto render(const Palette& palette, LogLevel level) const -> void
	{
		const auto visible_colors = std::count_if(
			palette.begin(), palette.end(), [](const Color& color) { return color.luminance() > 32.0; });

		switch (level) {
		case LogLevel::debug:
			std::cout << "debug";
			break;
		case LogLevel::info:
			std::cout << "info";
			break;
		case LogLevel::warning:
			std::cout << "warning";
			break;
		case LogLevel::error:
			throw std::runtime_error("preview renderer failed");
		}

		std::cout << ": " << visible_colors << " colors across " << width_ << " columns\n";
	}

private:
	std::string name_;
	std::size_t width_;
	std::optional<Color> accent_;
};

[[nodiscard]] auto make_palette() -> Palette
{
	constexpr Color cyan { .red = 0x3d, .green = 0xdb, .blue = 0xd9 };
	constexpr Color blue { .red = 120, .green = 169, .blue = 255 };
	constexpr Color violet { .red = 190, .green = 149, .blue = 255 };

	Palette colors { cyan, blue, violet };
	if (const auto [index, found] = LookupResult { 1, !colors.empty() }) {
		colors[index].red_channel() = first(colors[index].red, std::uint8_t { 0 });
		(void)found;
	}

	for (auto& color : colors) {
		color.red = clamp<std::uint8_t>(color.red, 16, 240);
	}

	return colors;
}

namespace keyword_reference {

template <class... Types>
struct TypeList final {
};

using FundamentalTypes = TypeList<
	bool,
	char,
	char8_t,
	char16_t,
	char32_t,
	wchar_t,
	signed char,
	unsigned char,
	short,
	unsigned short,
	int,
	unsigned int,
	long,
	unsigned long,
	long long,
	unsigned long long,
	float,
	double,
	long double,
	void>;

typedef signed short SignedShort;

alignas(64) constinit inline thread_local unsigned long event_counter = 0UL;
static inline constexpr bool feature_enabled = false;
inline constexpr auto null_address = nullptr;
extern volatile int external_signal;

union Word {
	std::uint32_t value;
	unsigned char bytes[sizeof(std::uint32_t)];
};

enum PlainState : unsigned {
	idle,
	running,
};

class Polymorphic {
public:
	virtual ~Polymorphic() = default;
	[[nodiscard]] virtual auto value() const noexcept -> int = 0;

protected:
	constexpr Polymorphic() = default;

private:
	friend class Concrete;
};

class Concrete final : public Polymorphic {
public:
	explicit constexpr Concrete(int value) noexcept
		: value_(value)
	{
	}

	[[nodiscard]] auto value() const noexcept -> int override { return value_; }

private:
	mutable int value_;
};

template <typename T>
concept Scalar = std::is_scalar_v<T>;

template <Scalar T>
	requires std::is_default_constructible_v<T>
consteval auto default_value() -> T
{
	return T {};
}

template <typename T>
[[nodiscard]] constexpr auto classify(T&& value) noexcept(noexcept(static_cast<int>(value))) -> decltype(auto)
{
	return static_cast<T&&>(value);
}

[[nodiscard]] inline auto inspect(Polymorphic* object, const void* address) -> std::size_t
{
	auto* created = new Concrete { 7 };
	auto* concrete = dynamic_cast<Concrete*>(object);
	auto* mutable_address = const_cast<void*>(address);
	const auto numeric_address = reinterpret_cast<std::uintptr_t>(mutable_address);
	const auto narrowed = static_cast<unsigned>(numeric_address);
	const auto object_size = sizeof(*created);
	const auto object_alignment = alignof(Concrete);
	const auto& dynamic_type = typeid(*object);

	delete created;
	(void)concrete;
	(void)narrowed;
	(void)dynamic_type;
	return object_size + object_alignment;
}

[[nodiscard]] constexpr auto alternative_tokens(unsigned left, unsigned right) -> bool
{
	auto mask = left;
	mask and_eq right;
	mask or_eq left;
	mask xor_eq right;
	return ((((left bitand right) not_eq 0U) and not ((left bitor right) == compl 0U))
			or ((left xor right) != 0U))
		and (mask not_eq compl 0U);
}

inline auto control_flow(int input) -> int
{
	auto result = 0;

	for (auto index = 0; index < input; ++index) {
		if (index == 2) {
			continue;
		} else if (index > 8) {
			break;
		}
		result += index;
	}

	do {
		--result;
	} while (result > input);

	switch (input) {
	case 0:
		result = default_value<int>();
		break;
	default:
		result += 1;
		break;
	}

	try {
		if (result < 0) {
			throw std::runtime_error("negative result");
		}
	} catch (const std::exception&) {
		goto recovery;
	}

	return result;

recovery:
	asm volatile("" ::: "memory");
	return -1;
}

static_assert(default_value<int>() == 0);
static_assert(alternative_tokens(3U, 1U));
static_assert(not feature_enabled and null_address == nullptr);

// Parsed by Tree-sitter for theme coverage, but excluded from compilation
// because these constructs require a dedicated module, coroutine, or
// contracts translation unit, or are reserved without current semantics.
#if 0
export module theme_preview.keyword_reference;
import <utility>;

register int reserved_for_future_use;

struct RelocationPreview final {
	auto coroutine() -> Task
	{
		co_await std::suspend_always {};
		co_yield 1;
		co_return;
	}
};

auto contracted(int value)
	pre(value >= 0)
	post(result: result >= 0)
	-> int
{
	contract_assert(value < 1'000);
	return value;
}
#endif

} // namespace keyword_reference

} // namespace theme_preview

auto main() -> int
{
	using theme_preview::Color;
	using theme_preview::LogLevel;
	using enum LogLevel;

	const std::string title = "Neovim theme preview";
	const std::string_view version = APP_VERSION;
	const char separator = ':';
	const bool diagnostics_enabled = true;
	const auto description = R"(black, gray, blue, violet)";

	theme_preview::Renderer renderer {
		title,
		static_cast<std::size_t>(theme_preview::kDefaultWidth * theme_preview::kGoldenRatio),
	};
	renderer.set_accent(Color { 61, 219, 217 });

	try {
		renderer.render(theme_preview::make_palette(), info);
		std::cout << version << separator << ' ' << description << '\n';
	} catch (const std::exception& error) {
		std::cerr << "error: " << error.what() << '\n';
		return 1;
	}

	return diagnostics_enabled ? 0 : 2;
}
