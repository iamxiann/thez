//#region node_modules/svelte/src/internal/shared/utils.js
var e = Array.isArray, t = Array.prototype.indexOf, n = Array.prototype.includes, r = Array.from, i = Object.defineProperty, a = Object.getOwnPropertyDescriptor, o = Object.getOwnPropertyDescriptors, s = Object.prototype, c = Array.prototype, l = Object.getPrototypeOf, u = Object.isExtensible, d = () => {};
function f(e) {
	for (var t = 0; t < e.length; t++) e[t]();
}
function p() {
	var e, t;
	return {
		promise: new Promise((n, r) => {
			e = n, t = r;
		}),
		resolve: e,
		reject: t
	};
}
var m = 1024, h = 2048, g = 4096, _ = 8192, v = 16384, y = 32768, b = 1 << 25, x = 65536, S = 1 << 19, ee = 1 << 20, te = 1 << 25, C = 65536, ne = 1 << 21, re = 1 << 22, ie = 1 << 23, ae = Symbol("$state"), oe = Symbol("component"), se = Symbol("legacy props"), ce = Symbol(""), le = Symbol("attributes"), ue = Symbol("class"), de = Symbol("style"), fe = Symbol("text"), pe = Symbol("form reset"), me = new class extends Error {
	name = "StaleReactionError";
	message = "The reaction that called `getAbortSignal()` was re-run or destroyed";
}(), he = !!globalThis.document?.contentType && /* @__PURE__ */ globalThis.document.contentType.includes("xml"), ge = {}, w = Symbol("uninitialized"), _e = "http://www.w3.org/1999/xhtml";
function ve() {
	console.warn("https://svelte.dev/e/derived_inert");
}
function ye(e) {
	console.warn("https://svelte.dev/e/hydration_mismatch");
}
function be() {
	console.warn("https://svelte.dev/e/svelte_boundary_reset_noop");
}
//#endregion
//#region node_modules/svelte/src/internal/client/dom/hydration.js
var T = !1;
function xe(e) {
	T = e;
}
var E;
function D(e) {
	if (e === null) throw ye(), ge;
	return E = e;
}
function Se() {
	return D(/* @__PURE__ */ Kt(E));
}
function O(e) {
	if (T) {
		if (/* @__PURE__ */ Kt(E) !== null) throw ye(), ge;
		E = e;
	}
}
function Ce(e = 1) {
	if (T) {
		for (var t = e, n = E; t--;) n = /* @__PURE__ */ Kt(n);
		E = n;
	}
}
function we(e = !0) {
	for (var t = 0, n = E;;) {
		if (n.nodeType === 8) {
			var r = n.data;
			if (r === "]") {
				if (t === 0) return n;
				--t;
			} else (r === "[" || r === "[!" || r[0] === "[" && !isNaN(Number(r.slice(1)))) && (t += 1);
		}
		var i = /* @__PURE__ */ Kt(n);
		e && n.remove(), n = i;
	}
}
function Te(e) {
	if (!e || e.nodeType !== 8) throw ye(), ge;
	return e.data;
}
//#endregion
//#region node_modules/svelte/src/internal/client/reactivity/equality.js
function Ee(e) {
	return e === this.v;
}
function De(e, t) {
	return e == e ? e !== t || typeof e == "object" && !!e || typeof e == "function" : t == t;
}
function Oe(e) {
	return !De(e, this.v);
}
//#endregion
//#region node_modules/svelte/src/internal/client/errors.js
function ke() {
	throw Error("https://svelte.dev/e/async_derived_orphan");
}
function Ae(e, t, n) {
	throw Error("https://svelte.dev/e/each_key_duplicate");
}
function je(e) {
	throw Error("https://svelte.dev/e/effect_in_teardown");
}
function Me() {
	throw Error("https://svelte.dev/e/effect_in_unowned_derived");
}
function Ne(e) {
	throw Error("https://svelte.dev/e/effect_orphan");
}
function Pe() {
	throw Error("https://svelte.dev/e/effect_update_depth_exceeded");
}
function Fe(e) {
	throw Error("https://svelte.dev/e/props_invalid_value");
}
function Ie() {
	throw Error("https://svelte.dev/e/state_descriptors_fixed");
}
function Le() {
	throw Error("https://svelte.dev/e/state_prototype_fixed");
}
function Re() {
	throw Error("https://svelte.dev/e/state_unsafe_mutation");
}
function ze() {
	throw Error("https://svelte.dev/e/svelte_boundary_reset_onerror");
}
//#endregion
//#region node_modules/svelte/src/internal/client/context.js
var k = null;
function Be(e) {
	k = e;
}
function Ve(e, t = !1, n) {
	k = {
		p: k,
		i: !1,
		c: null,
		e: null,
		s: e,
		x: null,
		r: q,
		l: null
	};
}
function He(e) {
	var t = k, n = t.e;
	if (n !== null) {
		t.e = null;
		for (var r of n) sn(r);
	}
	return e !== void 0 && (t.x = e), t.i = !0, k = t.p, Ue(e);
}
function Ue(e = {}) {
	return i(e, oe, { value: !0 }), e;
}
function We() {
	return !0;
}
//#endregion
//#region node_modules/svelte/src/internal/client/dom/task.js
var Ge = [];
function Ke() {
	var e = Ge;
	Ge = [], f(e);
}
function A(e) {
	if (Ge.length === 0 && !yt) {
		var t = Ge;
		queueMicrotask(() => {
			t === Ge && Ke();
		});
	}
	Ge.push(e);
}
//#endregion
//#region node_modules/svelte/src/internal/client/reactivity/status.js
var qe = ~(h | g | m);
function j(e, t) {
	e.f = e.f & qe | t;
}
function Je(e) {
	e.f & 512 || e.deps === null ? j(e, m) : j(e, g);
}
//#endregion
//#region node_modules/svelte/src/internal/client/reactivity/utils.js
function Ye(e) {
	if (e !== null) for (let t of e) !(t.f & 2) || !(t.f & 65536) || (t.f ^= C, Ye(t.deps));
}
function Xe(e, t, n) {
	e.f & 2048 ? t.add(e) : e.f & 4096 && n.add(e), Ye(e.deps), j(e, m);
}
//#endregion
//#region node_modules/svelte/src/internal/client/reactivity/store.js
var Ze = !1;
function Qe(e) {
	var t = Ze;
	try {
		return Ze = !1, [e(), Ze];
	} finally {
		Ze = t;
	}
}
//#endregion
//#region node_modules/svelte/src/internal/client/dom/elements/misc.js
var $e = !1;
function et() {
	$e || ($e = !0, document.addEventListener("reset", (e) => {
		Promise.resolve().then(() => {
			if (!e.defaultPrevented) for (let t of e.target.elements) t[pe]?.();
		});
	}, { capture: !0 }));
}
//#endregion
//#region node_modules/svelte/src/internal/client/dom/elements/bindings/shared.js
function tt(e) {
	var t = W, n = q;
	K(null), J(null);
	try {
		return e();
	} finally {
		K(t), J(n);
	}
}
//#endregion
//#region node_modules/svelte/src/internal/client/reactivity/async.js
function nt(e, t, n, r) {
	let i = We() ? ot : ut;
	var a = e.filter((e) => !e.settled), o = t.map(i);
	if (n.length === 0 && a.length === 0) {
		r(o);
		return;
	}
	var s = q, c = rt(), l = a.length === 1 ? a[0].promise : a.length > 1 ? Promise.all(a.map((e) => e.promise)) : null;
	function u(e) {
		if (!(s.f & 16384)) {
			c();
			try {
				r([...o, ...e]);
			} catch (e) {
				V(e, s);
			}
			it();
		}
	}
	var d = at();
	if (n.length === 0) {
		l.then(() => u([])).finally(d);
		return;
	}
	function f() {
		Promise.all(n.map((e) => /* @__PURE__ */ ct(e))).then(u).catch((e) => V(e, s)).finally(d);
	}
	l ? l.then(() => {
		c(), f(), it();
	}) : f();
}
function rt() {
	var e = q, t = W, n = k, r = M;
	return function(i = !0) {
		J(e), K(t), Be(n), i && !(e.f & 16384) && (r?.activate(), r?.apply());
	};
}
function it(e = !0) {
	J(null), K(null), Be(null), e && M?.deactivate();
}
function at() {
	var e = q, t = e.b, n = M, r = !!t?.is_rendered();
	return t?.update_pending_count(1, n), n.increment(r, e), () => {
		t?.update_pending_count(-1, n), n.decrement(r, e);
	};
}
/*#__NO_SIDE_EFFECTS__*/
function ot(e) {
	var t = 2 | h;
	return q !== null && (q.f |= S), {
		ctx: k,
		deps: null,
		effects: null,
		equals: Ee,
		f: t,
		fn: e,
		reactions: null,
		rv: 0,
		v: w,
		wv: 0,
		parent: q,
		ac: null
	};
}
var st = Symbol("obsolete");
/*#__NO_SIDE_EFFECTS__*/
function ct(e, t, n) {
	let r = q;
	r === null && ke();
	var i = void 0, a = Nt(w), o = !W, s = /* @__PURE__ */ new Set();
	return ln(() => {
		var t = q, n = p();
		i = n.promise;
		try {
			Promise.resolve(e()).then(n.resolve, (e) => {
				e !== me && n.reject(e);
			}).finally(it);
		} catch (e) {
			n.reject(e), it();
		}
		var c = M;
		if (o) {
			if (t.f & 32768) var l = at();
			if (r.b?.is_rendered()) c.async_deriveds.get(t)?.reject(st);
			else for (let e of s.values()) e.reject(st);
			s.add(n), c.async_deriveds.set(t, n);
		}
		let u = (e, t = void 0) => {
			l?.(), s.delete(n), t !== st && (c.activate(), t ? (a.f |= ie, Ft(a, t)) : (a.f & 8388608 && (a.f ^= ie), Ft(a, e)), c.deactivate());
		};
		n.promise.then(u, (e) => u(null, e || "unknown"));
	}), an(() => {
		for (let e of s) e.reject(st);
	}), new Promise((e) => {
		function t(n) {
			function r() {
				n === i ? e(a) : t(i);
			}
			n.then(r, r);
		}
		t(i);
	});
}
/*#__NO_SIDE_EFFECTS__*/
function lt(e) {
	let t = /* @__PURE__ */ ot(e);
	return Dn(t), t;
}
/*#__NO_SIDE_EFFECTS__*/
function ut(e) {
	let t = /* @__PURE__ */ ot(e);
	return t.equals = Oe, t;
}
function dt(e) {
	var t = e.effects;
	if (t !== null) {
		e.effects = null;
		for (var n = 0; n < t.length; n += 1) U(t[n]);
	}
}
function ft(e) {
	var t, n = q, r = e.parent;
	if (!Tn && r !== null && e.v !== w && r.f & 24576) return ve(), e.v;
	J(r);
	try {
		e.f &= ~C, dt(e), t = In(e);
	} finally {
		J(n);
	}
	return t;
}
function pt(e) {
	var t = ft(e);
	if (!e.equals(t) && (e.wv = Nn(), (!M?.is_fork || e.deps === null) && (M === null ? e.v = t : (M.capture(e, t, !0), _t?.capture(e, t, !0)), e.deps === null))) {
		j(e, m);
		return;
	}
	Tn || (N === null ? Je(e) : (rn() || M?.is_fork) && N.set(e, t));
}
function mt(e) {
	if (e.effects !== null) for (let t of e.effects) (t.teardown || t.ac) && (t.teardown?.(), t.ac !== null && tt(() => {
		t.ac.abort(me), t.ac = null;
	}), t.fn !== null && (t.teardown = d), zn(t, 0), mn(t));
}
function ht(e) {
	if (e.effects !== null) for (let t of e.effects) t.teardown && t.fn !== null && Bn(t);
}
//#endregion
//#region node_modules/svelte/src/internal/client/reactivity/batch.js
var gt = null, M = null, _t = null, N = null, vt = null, yt = !1, bt = !1, xt = null, St = null, Ct = 0, wt = 1, Tt = class e {
	id = wt++;
	#e = !1;
	linked = !0;
	#t = null;
	#n = null;
	async_deriveds = /* @__PURE__ */ new Map();
	current = /* @__PURE__ */ new Map();
	previous = /* @__PURE__ */ new Map();
	#r = /* @__PURE__ */ new Set();
	#i = /* @__PURE__ */ new Set();
	#a = 0;
	#o = /* @__PURE__ */ new Map();
	#s = null;
	#c = [];
	#l = [];
	#u = /* @__PURE__ */ new Set();
	#d = /* @__PURE__ */ new Set();
	#f = /* @__PURE__ */ new Map();
	#p = /* @__PURE__ */ new Set();
	is_fork = !1;
	#m = !1;
	constructor() {
		gt === null ? gt = this : (gt.#n = this, this.#t = gt), gt = this;
	}
	#h() {
		if (this.is_fork) return !0;
		for (let n of this.#o.keys()) {
			for (var e = n, t = !1; e.parent !== null;) {
				if (this.#f.has(e)) {
					t = !0;
					break;
				}
				e = e.parent;
			}
			if (!t) return !0;
		}
		return !1;
	}
	skip_effect(e) {
		this.#f.has(e) || this.#f.set(e, {
			d: [],
			m: []
		}), this.#p.delete(e);
	}
	unskip_effect(e, t = (e) => this.schedule(e)) {
		var n = this.#f.get(e);
		if (n) {
			this.#f.delete(e);
			for (var r of n.d) j(r, h), t(r);
			for (r of n.m) j(r, g), t(r);
		}
		this.#p.add(e);
	}
	#g() {
		this.#e = !0, Ct++ > 1e3 && (this.#x(), Et());
		for (let e of this.#u) this.#d.delete(e), j(e, h), this.schedule(e);
		for (let e of this.#d) j(e, g), this.schedule(e);
		let t = this.#c;
		this.#c = [], this.apply();
		var n = xt = [], r = [], i = St = [];
		for (let e of t) try {
			this.#_(e, n, r);
		} catch (t) {
			throw At(e), this.#h() || this.discard(), t;
		}
		if (M = null, i.length > 0) {
			var a = e.ensure();
			for (let e of i) a.schedule(e);
		}
		if (xt = null, St = null, this.#h()) {
			this.#b(r), this.#b(n);
			for (let [e, t] of this.#f) kt(e, t);
			i.length > 0 && M.#g();
			return;
		}
		let o = this.#v();
		if (o) {
			this.#b(r), this.#b(n), o.#y(this);
			return;
		}
		this.#u.clear(), this.#d.clear();
		for (let e of this.#r) e(this);
		this.#r.clear(), _t = this, Dt(r), Dt(n), _t = null, this.#s?.resolve();
		var s = M;
		if (this.#a === 0 && (this.#c.length === 0 || s !== null) && this.#x(), this.#c.length > 0) {
			if (s !== null) {
				let e = s;
				e.#c.push(...this.#c.filter((t) => !e.#c.includes(t)));
			} else s = this;
		}
		s !== null && (F.clear(), s.#g());
	}
	#_(e, t, n) {
		e.f ^= m;
		for (var r = e.first; r !== null;) {
			var i = r.f, a = !!(i & 96);
			if (!(a && i & 1024 || i & 8192 || this.#f.has(r)) && r.fn !== null) {
				a ? r.f ^= m : i & 4 ? t.push(r) : Pn(r) && (i & 16 && this.#d.add(r), Bn(r));
				var o = r.first;
				if (o !== null) {
					r = o;
					continue;
				}
			}
			for (; r !== null;) {
				var s = r.next;
				if (s !== null) {
					r = s;
					break;
				}
				r = r.parent;
			}
		}
	}
	#v() {
		for (var e = this.#t; e !== null;) {
			if (!e.is_fork) {
				for (let [t, [, n]] of this.current) if (e.current.has(t) && !n) return e;
			}
			e = e.#t;
		}
		return null;
	}
	#y(e) {
		for (let [t, n] of e.current) !this.previous.has(t) && e.previous.has(t) && this.previous.set(t, e.previous.get(t)), this.current.set(t, n);
		for (let [t, n] of e.async_deriveds) {
			let e = this.async_deriveds.get(t);
			e && n.promise.then(e.resolve).catch(e.reject);
		}
		e.async_deriveds.clear(), this.transfer_effects(e.#u, e.#d);
		let t = (e) => {
			var n = e.reactions;
			if (n !== null && !(e.f & 2 && !(e.f & 6144))) for (let e of n) {
				var r = e.f;
				if (r & 2) t(e);
				else {
					var i = e;
					r & 4194320 && !this.async_deriveds.has(i) && (this.#d.delete(i), j(i, h), this.schedule(i));
				}
			}
		};
		for (let e of this.current.keys()) t(e);
		this.oncommit(() => e.discard()), e.#x(), M = this, this.#g();
	}
	#b(e) {
		for (var t = 0; t < e.length; t += 1) Xe(e[t], this.#u, this.#d);
	}
	capture(e, t, n = !1) {
		e.v !== w && !this.previous.has(e) && this.previous.set(e, e.v), e.f & 8388608 || (this.current.set(e, [t, n]), N?.set(e, t)), this.is_fork || (e.v = t);
	}
	activate() {
		M = this;
	}
	deactivate() {
		M = null, N = null;
	}
	flush() {
		try {
			bt = !0, M = this, this.#g();
		} finally {
			Ct = 0, vt = null, xt = null, St = null, bt = !1, M = null, N = null, F.clear();
		}
	}
	discard() {
		for (let e of this.#i) e(this);
		this.#i.clear();
		for (let e of this.async_deriveds.values()) e.reject(st);
		this.#x(), this.#s?.resolve();
	}
	register_created_effect(e) {
		this.#l.push(e);
	}
	increment(e, t) {
		if (this.#a += 1, e) {
			let e = this.#o.get(t) ?? 0;
			this.#o.set(t, e + 1);
		}
	}
	decrement(e, t) {
		if (--this.#a, e) {
			let e = this.#o.get(t) ?? 0;
			e === 1 ? this.#o.delete(t) : this.#o.set(t, e - 1);
		}
		this.#m || (this.#m = !0, A(() => {
			this.#m = !1, this.linked && this.flush();
		}));
	}
	transfer_effects(e, t) {
		for (let t of e) this.#u.add(t);
		for (let e of t) this.#d.add(e);
		e.clear(), t.clear();
	}
	oncommit(e) {
		this.#r.add(e);
	}
	ondiscard(e) {
		this.#i.add(e);
	}
	settled() {
		return (this.#s ??= p()).promise;
	}
	static ensure() {
		if (M === null) {
			let t = M = new e();
			!bt && A(() => {
				t.#e || t.flush();
			});
		}
		return M;
	}
	apply() {
		N = null;
	}
	schedule(e) {
		if (vt = e, e.b?.is_pending && e.f & 16777228 && !(e.f & 32768)) {
			e.b.defer_effect(e);
			return;
		}
		for (var t = e; t.parent !== null;) {
			t = t.parent;
			var n = t.f;
			if (xt !== null && t === q && (W === null || !(W.f & 2))) return;
			if (n & 96) {
				if (!(n & 1024)) return;
				t.f ^= m;
			}
		}
		this.#c.push(t);
	}
	#x() {
		if (this.linked) {
			var e = this.#t, t = this.#n;
			e === null || (e.#n = t), t === null ? gt = e : t.#t = e, this.linked = !1;
		}
	}
};
function Et() {
	try {
		Pe();
	} catch (e) {
		V(e, vt);
	}
}
var P = null;
function Dt(e) {
	var t = e.length;
	if (t !== 0) {
		for (var n = 0; n < t;) {
			var r = e[n++];
			if (!(r.f & 24576) && Pn(r) && (P = /* @__PURE__ */ new Set(), Bn(r), r.deps === null && r.first === null && r.nodes === null && r.teardown === null && r.ac === null && _n(r), P?.size > 0)) {
				F.clear();
				for (let e of P) {
					if (e.f & 24576) continue;
					let t = [e], n = e.parent;
					for (; n !== null;) P.has(n) && (P.delete(n), t.push(n)), n = n.parent;
					for (let e = t.length - 1; e >= 0; e--) {
						let n = t[e];
						n.f & 24576 || Bn(n);
					}
				}
				P.clear();
			}
		}
		P = null;
	}
}
function Ot(e) {
	M.schedule(e);
}
function kt(e, t) {
	if (!(e.f & 32 && e.f & 1024)) {
		e.f & 2048 ? t.d.push(e) : e.f & 4096 && t.m.push(e), j(e, m);
		for (var n = e.first; n !== null;) kt(n, t), n = n.next;
	}
}
function At(e) {
	j(e, m);
	for (var t = e.first; t !== null;) At(t), t = t.next;
}
//#endregion
//#region node_modules/svelte/src/internal/client/reactivity/sources.js
var jt = /* @__PURE__ */ new Set(), F = /* @__PURE__ */ new Map(), Mt = !1;
function Nt(e, t) {
	return {
		f: 0,
		v: e,
		reactions: null,
		equals: Ee,
		rv: 0,
		wv: 0
	};
}
/*#__NO_SIDE_EFFECTS__*/
function I(e, t) {
	let n = Nt(e, t);
	return Dn(n), n;
}
/*#__NO_SIDE_EFFECTS__*/
function Pt(e, t = !1, n = !0) {
	let r = Nt(e);
	return t || (r.equals = Oe), r;
}
function L(e, t, n = !1) {
	return W !== null && (!G || W.f & 131072) && We() && W.f & 4325394 && (Y === null || !Y.has(e)) && Re(), Ft(e, n ? zt(t) : t, St);
}
function Ft(e, t, n = null) {
	if (!e.equals(t)) {
		Tn ? F.set(e, t) : F.has(e) || F.set(e, e.v);
		var r = Tt.ensure();
		if (r.capture(e, t), e.f & 2) {
			let t = e;
			e.f & 2048 && ft(t), N === null && Je(t);
		}
		e.wv = Nn(), Rt(e, h, n), We() && q !== null && q.f & 1024 && !(q.f & 96) && (Q === null ? On([e]) : Q.push(e)), !r.is_fork && jt.size > 0 && !Mt && It();
	}
	return t;
}
function It() {
	Mt = !1;
	for (let e of jt) {
		e.f & 1024 && j(e, g);
		let t;
		try {
			t = Pn(e);
		} catch {
			t = !0;
		}
		t && Bn(e);
	}
	jt.clear();
}
function Lt(e) {
	L(e, e.v + 1);
}
function Rt(e, t, n) {
	var r = e.reactions;
	if (r !== null) for (var i = We(), a = r.length, o = 0; o < a; o++) {
		var s = r[o], c = s.f;
		if (!(!i && s === q)) {
			var l = (c & h) === 0;
			if (l && j(s, t), c & 131072) jt.add(s);
			else if (c & 2) {
				var u = s;
				N?.delete(u), c & 65536 || (c & 512 && (q === null || !(q.f & 2097152)) && (s.f |= C), Rt(u, g, n));
			} else if (l) {
				var d = s;
				c & 16 && P !== null && P.add(d), n === null ? Ot(d) : n.push(d);
			}
		}
	}
}
function zt(t) {
	if (typeof t != "object" || !t || ae in t || oe in t) return t;
	let n = l(t);
	if (n !== s && n !== c) return t;
	var r = /* @__PURE__ */ new Map(), i = e(t), o = /* @__PURE__ */ I(0), u = null, d = jn, f = (e) => {
		if (jn === d) return e();
		var t = W, n = jn;
		K(null), Mn(d);
		var r = e();
		return K(t), Mn(n), r;
	};
	return i && r.set("length", /* @__PURE__ */ I(t.length, u)), new Proxy(t, {
		defineProperty(e, t, n) {
			(!("value" in n) || n.configurable === !1 || n.enumerable === !1 || n.writable === !1) && Ie();
			var i = r.get(t);
			return i === void 0 ? f(() => {
				var e = /* @__PURE__ */ I(n.value, u);
				return r.set(t, e), e;
			}) : L(i, n.value, !0), !0;
		},
		deleteProperty(e, t) {
			var n = r.get(t);
			if (n === void 0) {
				if (t in e) {
					let e = f(() => /* @__PURE__ */ I(w, u));
					r.set(t, e), Lt(o);
				}
			} else L(n, w), Lt(o);
			return !0;
		},
		get(e, n, i) {
			if (n === ae) return t;
			var o = r.get(n), s = n in e;
			if (o === void 0 && (!s || a(e, n)?.writable) && (o = f(() => /* @__PURE__ */ I(zt(s ? e[n] : w), u)), r.set(n, o)), o !== void 0) {
				var c = $(o);
				return c === w ? void 0 : c;
			}
			return Reflect.get(e, n, i);
		},
		getOwnPropertyDescriptor(e, t) {
			var n = Reflect.getOwnPropertyDescriptor(e, t);
			if (n && "value" in n) {
				var i = r.get(t);
				i && (n.value = $(i));
			} else if (n === void 0) {
				var a = r.get(t), o = a?.v;
				if (a !== void 0 && o !== w) return {
					enumerable: !0,
					configurable: !0,
					value: o,
					writable: !0
				};
			}
			return n;
		},
		has(e, t) {
			if (t === ae) return !0;
			var n = r.get(t), i = n !== void 0 && n.v !== w || Reflect.has(e, t);
			return (n !== void 0 || q !== null && (!i || a(e, t)?.writable)) && (n === void 0 && (n = f(() => /* @__PURE__ */ I(i ? zt(e[t]) : w, u)), r.set(t, n)), $(n) === w) ? !1 : i;
		},
		set(e, t, n, s) {
			var c = r.get(t), l = t in e;
			if (i && t === "length") for (var d = n; d < c.v; d += 1) {
				var p = r.get(d + "");
				p === void 0 ? d in e && (p = f(() => /* @__PURE__ */ I(w, u)), r.set(d + "", p)) : L(p, w);
			}
			if (c === void 0) (!l || a(e, t)?.writable) && (c = f(() => /* @__PURE__ */ I(void 0, u)), L(c, zt(n)), r.set(t, c));
			else {
				l = c.v !== w;
				var m = f(() => zt(n));
				L(c, m);
			}
			var h = Reflect.getOwnPropertyDescriptor(e, t);
			if (h?.set && h.set.call(s, n), !l) {
				if (i && typeof t == "string") {
					var g = r.get("length"), _ = Number(t);
					Number.isInteger(_) && _ >= g.v && L(g, _ + 1);
				}
				Lt(o);
			}
			return !0;
		},
		ownKeys(e) {
			$(o);
			var t = Reflect.ownKeys(e).filter((e) => {
				var t = r.get(e);
				return t === void 0 || t.v !== w;
			});
			for (var [n, i] of r) i.v !== w && !(n in e) && t.push(n);
			return t;
		},
		setPrototypeOf() {
			Le();
		}
	});
}
var Bt, Vt, Ht, Ut;
function Wt() {
	if (Bt === void 0) {
		Bt = window, Vt = /Firefox/.test(navigator.userAgent);
		var e = Element.prototype, t = Node.prototype, n = Text.prototype;
		Ht = a(t, "firstChild").get, Ut = a(t, "nextSibling").get, u(e) && (e[ue] = void 0, e[le] = null, e[de] = void 0, e.__e = void 0), u(n) && (n[fe] = void 0);
	}
}
function R(e = "") {
	return document.createTextNode(e);
}
/*@__NO_SIDE_EFFECTS__*/
function Gt(e) {
	return Ht.call(e);
}
/*@__NO_SIDE_EFFECTS__*/
function Kt(e) {
	return Ut.call(e);
}
function z(e, t) {
	if (!T) return /* @__PURE__ */ Gt(e);
	var n = /* @__PURE__ */ Gt(E);
	if (n === null) n = E.appendChild(R());
	else if (t && n.nodeType !== 3) {
		var r = R();
		return n?.before(r), D(r), r;
	}
	return t && Qt(n), D(n), n;
}
function qt(e, t = !1) {
	if (!T) {
		var n = /* @__PURE__ */ Gt(e);
		return n instanceof Comment && n.data === "" ? /* @__PURE__ */ Kt(n) : n;
	}
	if (t) {
		if (E?.nodeType !== 3) {
			var r = R();
			return E?.before(r), D(r), r;
		}
		Qt(E);
	}
	return E;
}
function Jt(e, t = !1) {
	if (!T) return /* @__PURE__ */ Gt(e);
	var n = z(e, t);
	return O(e), n;
}
function B(e, t = 1, n = !1) {
	let r = T ? E : e;
	for (var i; t--;) i = r, r = /* @__PURE__ */ Kt(r);
	if (!T) return r;
	if (n) {
		if (r?.nodeType !== 3) {
			var a = R();
			return r === null ? i?.after(a) : r.before(a), D(a), a;
		}
		Qt(r);
	}
	return D(r), r;
}
function Yt(e) {
	e.textContent = "";
}
function Xt() {
	return !1;
}
function Zt(e, t, n) {
	return t == null || t === "http://www.w3.org/1999/xhtml" ? n ? document.createElement(e, { is: n }) : document.createElement(e) : n ? document.createElementNS(t, e, { is: n }) : document.createElementNS(t, e);
}
function Qt(e) {
	if (e.nodeValue.length < 65536) return;
	let t = e.nextSibling;
	for (; t !== null && t.nodeType === 3;) t.remove(), e.nodeValue += t.nodeValue, t = e.nextSibling;
}
function $t(e) {
	var t = q;
	if (t === null) return W.f |= ie, e;
	if (!(t.f & 32768) && !(t.f & 4)) throw e;
	V(e, t);
}
function V(e, t) {
	if (!(t !== null && t.f & 16384)) {
		for (; t !== null;) {
			if (t.f & 128 && !(t.f & 33570816)) {
				if (!(t.f & 32768)) throw e;
				try {
					t.b.error(e);
					return;
				} catch (t) {
					e = t;
				}
			}
			t = t.parent;
		}
		throw e;
	}
}
//#endregion
//#region node_modules/svelte/src/internal/client/reactivity/effects.js
function en(e) {
	q === null && (W === null && Ne(e), Me()), Tn && je(e);
}
function tn(e, t) {
	var n = t.last;
	n === null ? t.last = t.first = e : (n.next = e, e.prev = n, t.last = e);
}
function nn(e, t) {
	var n = q;
	n !== null && n.f & 8192 && (e |= _);
	var r = {
		ctx: k,
		deps: null,
		nodes: null,
		f: e | h | 512,
		first: null,
		fn: t,
		last: null,
		next: null,
		parent: n,
		b: n && n.b,
		prev: null,
		teardown: null,
		wv: 0,
		ac: null
	};
	M?.register_created_effect(r);
	var i = r;
	if (e & 4) xt === null ? Tt.ensure().schedule(r) : xt.push(r);
	else if (t !== null) {
		try {
			Bn(r);
		} catch (e) {
			throw U(r), e;
		}
		i.deps === null && i.teardown === null && i.nodes === null && i.first === i.last && !(i.f & 524288) && (i = i.first, e & 16 && e & 65536 && i !== null && (i.f |= x));
	}
	if (i !== null && (i.parent = n, n !== null && tn(i, n), W !== null && W.f & 2 && !(e & 64))) {
		var a = W;
		(a.effects ??= []).push(i);
	}
	return r;
}
function rn() {
	return W !== null && !G;
}
function an(e) {
	let t = nn(8, null);
	return j(t, m), t.teardown = e, t;
}
function on(e) {
	en("$effect");
	var t = q.f;
	if (!W && t & 32 && k !== null && !k.i) {
		var n = k;
		(n.e ??= []).push(e);
	} else return sn(e);
}
function sn(e) {
	return nn(4 | ee, e);
}
function cn(e) {
	Tt.ensure();
	let t = nn(64 | S, e);
	return (e = {}) => new Promise((n) => {
		e.outro ? vn(t, () => {
			U(t), n(void 0);
		}) : (U(t), n(void 0));
	});
}
function ln(e) {
	return nn(re | S, e);
}
function un(e, t = 0) {
	return nn(8 | t, e);
}
function dn(e, t = [], n = [], r = []) {
	nt(r, t, n, (t) => {
		nn(8, () => {
			e(...t.map($));
		});
	});
}
function fn(e, t = 0) {
	return nn(16 | t, e);
}
function H(e) {
	return nn(32 | S, e);
}
function pn(e) {
	var t = e.teardown;
	if (t !== null) {
		let n = Tn, r = W;
		En(!0), K(null);
		try {
			t.call(null);
		} catch (t) {
			V(t, e.parent);
		} finally {
			En(n), K(r);
		}
	}
}
function mn(e, t = !1) {
	var n = e.first;
	for (e.first = e.last = null; n !== null;) {
		let e = n.ac;
		e !== null && tt(() => {
			e.abort(me);
		});
		var r = n.next;
		n.f & 64 ? n.parent = null : U(n, t), n = r;
	}
}
function hn(e) {
	for (var t = e.first; t !== null;) {
		var n = t.next;
		t.f & 32 || U(t), t = n;
	}
}
function U(e, t = !0) {
	var n = !1;
	(t || e.f & 262144) && e.nodes !== null && e.nodes.end !== null && (gn(e.nodes.start, e.nodes.end), n = !0), e.f |= b, mn(e, t && !n), zn(e, 0);
	var r = e.nodes && e.nodes.t;
	if (r !== null) for (let e of r) e.stop();
	pn(e), e.f ^= b, e.f |= v;
	var i = e.parent;
	i !== null && i.first !== null && _n(e), e.next = e.prev = e.teardown = e.ctx = e.deps = e.fn = e.nodes = e.ac = e.b = null;
}
function gn(e, t) {
	for (; e !== null;) {
		var n = e === t ? null : /* @__PURE__ */ Kt(e);
		e.remove(), e = n;
	}
}
function _n(e) {
	var t = e.parent, n = e.prev, r = e.next;
	n !== null && (n.next = r), r !== null && (r.prev = n), t !== null && (t.first === e && (t.first = r), t.last === e && (t.last = n));
}
function vn(e, t, n = !0) {
	var r = [];
	e.f |= 256, yn(e, r, !0);
	var i = () => {
		n && U(e), t && t();
	}, a = r.length;
	if (a > 0) {
		var o = () => --a || i();
		for (var s of r) s.out(o);
	} else i();
}
function yn(e, t, n) {
	if (!(e.f & 8192)) {
		e.f ^= _;
		var r = e.nodes && e.nodes.t;
		if (r !== null) for (let e of r) (e.is_global || n) && t.push(e);
		for (var i = e.first; i !== null;) {
			var a = i.next;
			if (!(i.f & 64)) {
				var o = !!(i.f & 65536) || !!(i.f & 32) && !!(e.f & 16);
				yn(i, t, o ? n : !1);
			}
			i = a;
		}
	}
}
function bn(e) {
	e.f &= -257, xn(e, !0);
}
function xn(e, t) {
	if (!(e.f & 256) && e.f & 8192) {
		e.f ^= _, e.f & 1024 || (j(e, h), Tt.ensure().schedule(e));
		for (var n = e.first; n !== null;) {
			var r = n.next, i = !!(n.f & 65536) || !!(n.f & 32);
			xn(n, i ? t : !1), n = r;
		}
		var a = e.nodes && e.nodes.t;
		if (a !== null) for (let e of a) (e.is_global || t) && e.in();
	}
}
function Sn(e, t) {
	if (e.nodes) for (var n = e.nodes.start, r = e.nodes.end; n !== null;) {
		var i = n === r ? null : /* @__PURE__ */ Kt(n);
		t.append(n), n = i;
	}
}
//#endregion
//#region node_modules/svelte/src/internal/client/legacy.js
var Cn = null, wn = !1, Tn = !1;
function En(e) {
	Tn = e;
}
var W = null, G = !1;
function K(e) {
	W = e;
}
var q = null;
function J(e) {
	q = e;
}
var Y = null;
function Dn(e) {
	W !== null && (Y ??= /* @__PURE__ */ new Set()).add(e);
}
var X = null, Z = 0, Q = null;
function On(e) {
	Q = e;
}
var kn = 1, An = 0, jn = An;
function Mn(e) {
	jn = e;
}
function Nn() {
	return ++kn;
}
function Pn(e) {
	var t = e.f;
	if (t & 2048) return !0;
	if (t & 2 && (e.f &= ~C), t & 4096) {
		for (var n = e.deps, r = n.length, i = 0; i < r; i++) {
			var a = n[i];
			if (Pn(a) && pt(a), a.wv > e.wv) return !0;
		}
		t & 512 && N === null && j(e, m);
	}
	return !1;
}
function Fn(e, t, n = !0) {
	var r = e.reactions;
	if (r !== null && !(Y !== null && Y.has(e))) for (var i = 0; i < r.length; i++) {
		var a = r[i];
		a.f & 2 ? Fn(a, t, !1) : t === a && (n ? j(a, h) : a.f & 1024 && j(a, g), Ot(a));
	}
}
function In(e) {
	var t = X, n = Z, r = Q, i = W, a = Y, o = k, s = G, c = jn, l = e.f;
	X = null, Z = 0, Q = null, W = l & 96 ? null : e, Y = null, Be(e.ctx), G = !1, jn = ++An, e.ac !== null && (tt(() => {
		e.ac.abort(me);
	}), e.ac = null);
	try {
		e.f |= ne;
		var u = e.fn, d = u();
		e.f |= y;
		var f = Ln(e);
		if (We() && Q !== null && !G && f !== null && !(e.f & 6146)) for (var p = 0; p < Q.length; p++) Fn(Q[p], e);
		if (i !== null && i !== e) {
			if (An++, i.deps !== null) for (let e = 0; e < n; e += 1) i.deps[e].rv = An;
			if (t !== null) for (let e of t) e.rv = An;
			Q !== null && (r === null ? r = Q : r.push(...Q));
		}
		return e.f & 8388608 && (e.f ^= ie), d;
	} catch (t) {
		return Ln(e), $t(t);
	} finally {
		e.f ^= ne, X = t, Z = n, Q = r, W = i, Y = a, Be(o), G = s, jn = c;
	}
}
function Ln(e) {
	var t = e.deps, n = M?.is_fork;
	if (X !== null) {
		var r;
		if (n || zn(e, Z), t !== null && Z > 0) for (t.length = Z + X.length, r = 0; r < X.length; r++) t[Z + r] = X[r];
		else e.deps = t = X;
		if (rn() && e.f & 512) for (r = Z; r < t.length; r++) (t[r].reactions ??= []).push(e);
	} else !n && t !== null && Z < t.length && (zn(e, Z), t.length = Z);
	return t;
}
function Rn(e, r) {
	let i = r.reactions;
	if (i !== null) {
		var a = t.call(i, e);
		if (a !== -1) {
			var o = i.length - 1;
			o === 0 ? i = r.reactions = null : (i[a] = i[o], i.pop());
		}
	}
	if (i === null && r.f & 2 && (X === null || !n.call(X, r))) {
		var s = r;
		s.f & 512 && (s.f ^= 512, s.f &= ~C), s.v !== w && Je(s), s.ac !== null && tt(() => {
			s.ac.abort(me), s.ac = null, j(s, h);
		}), mt(s), zn(s, 0);
	}
}
function zn(e, t) {
	var n = e.deps;
	if (n !== null) for (var r = t; r < n.length; r++) Rn(e, n[r]);
}
function Bn(e) {
	var t = e.f;
	if (!(t & 16384)) {
		j(e, m);
		var n = q, r = wn;
		q = e, wn = !(t & 96);
		try {
			t & 16777232 ? hn(e) : mn(e), pn(e);
			var i = In(e);
			e.teardown = typeof i == "function" ? i : null, e.wv = kn;
		} finally {
			wn = r, q = n;
		}
	}
}
function $(e) {
	var t = !!(e.f & 2);
	if (Cn?.add(e), W !== null && !G && !(q !== null && q.f & 16384) && (Y === null || !Y.has(e))) {
		var r = W.deps;
		if (W.f & 2097152) e.rv < An && (e.rv = An, X === null && r !== null && r[Z] === e ? Z++ : X === null ? X = [e] : X.push(e));
		else {
			W.deps ??= [], n.call(W.deps, e) || W.deps.push(e);
			var i = e.reactions;
			i === null ? e.reactions = [W] : n.call(i, W) || i.push(W);
		}
	}
	if (Tn && F.has(e)) return F.get(e);
	if (t) {
		var a = e;
		if (Tn) {
			var o = a.v;
			return (!(a.f & 1024) && a.reactions !== null || Hn(a)) && (o = ft(a)), F.set(a, o), o;
		}
		var s = !(a.f & 512) && !G && W !== null && (wn || !!(W.f & 512)), c = (a.f & y) === 0;
		Pn(a) && (s && (a.f |= 512), pt(a)), s && !c && (ht(a), Vn(a));
	}
	if (N?.has(e)) return N.get(e);
	if (e.f & 8388608) throw e.v;
	return e.v;
}
function Vn(e) {
	if (e.f |= 512, e.deps !== null) for (let t of e.deps) (t.reactions ??= []).push(e), t.f & 2 && !(t.f & 512) && (ht(t), Vn(t));
}
function Hn(e) {
	if (e.v === w) return !0;
	if (e.deps === null) return !1;
	for (let t of e.deps) if (F.has(t) || t.f & 2 && Hn(t)) return !0;
	return !1;
}
function Un(e) {
	var t = G;
	try {
		return G = !0, e();
	} finally {
		G = t;
	}
}
[.../* @__PURE__ */ "allowfullscreen.async.autofocus.autoplay.checked.controls.default.disabled.formnovalidate.indeterminate.inert.ismap.loop.multiple.muted.nomodule.novalidate.open.playsinline.readonly.required.reversed.seamless.selected.webkitdirectory.defer.disablepictureinpicture.disableremoteplayback".split(".")];
var Wn = ["touchstart", "touchmove"];
function Gn(e) {
	return Wn.includes(e);
}
//#endregion
//#region node_modules/svelte/src/internal/client/dom/elements/events.js
var Kn = Symbol("events"), qn = /* @__PURE__ */ new Set(), Jn = /* @__PURE__ */ new Set();
function Yn(e, t, n, r = {}) {
	function i(e) {
		if (r.capture || tr.call(t, e), !e.cancelBubble) return tt(() => n?.call(this, e));
	}
	return e.startsWith("pointer") || e.startsWith("touch") || e === "wheel" ? A(() => {
		t.addEventListener(e, i, r);
	}) : t.addEventListener(e, i, r), i;
}
function Xn(e, t, n, r, i) {
	var a = {
		capture: r,
		passive: i
	}, o = Yn(e, t, n, a);
	(t === document.body || t === window || t === document || t instanceof HTMLMediaElement) && an(() => {
		t.removeEventListener(e, o, a);
	});
}
function Zn(e, t, n) {
	(t[Kn] ??= {})[e] = n;
}
function Qn(e) {
	for (var t = 0; t < e.length; t++) qn.add(e[t]);
	for (var n of Jn) n(e);
}
var $n = null, er = !1;
function tr(e) {
	var t = this, n = t.ownerDocument, r = e.type, a = e.composedPath?.() || [], o = a[0] || e.target;
	$n = e, er || (er = !0, setTimeout(() => {
		er = !1, $n = null;
	}));
	var s = 0, c = $n === e && e[Kn];
	if (c) {
		var l = a.indexOf(c);
		if (l !== -1 && (t === document || t === window)) {
			e[Kn] = t;
			return;
		}
		var u = a.indexOf(t);
		if (u === -1) return;
		l <= u && (s = l);
	}
	if (o = a[s] || e.target, o !== t) {
		i(e, "currentTarget", {
			configurable: !0,
			get() {
				return o || n;
			}
		});
		var d = W, f = q;
		K(null), J(null);
		try {
			for (var p, m = []; o !== null && o !== t;) {
				try {
					var h = o[Kn]?.[r];
					h != null && (!o.disabled || e.target === o) && h.call(o, e);
				} catch (e) {
					p ? m.push(e) : p = e;
				}
				if (e.cancelBubble) break;
				s++, o = s < a.length ? a[s] : null;
			}
			if (p) {
				for (let e of m) queueMicrotask(() => {
					throw e;
				});
				throw p;
			}
		} finally {
			e[Kn] = t, delete e.currentTarget, K(d), J(f);
		}
	}
}
//#endregion
//#region node_modules/svelte/src/internal/client/dom/reconciler.js
var nr = globalThis?.window?.trustedTypes && /* @__PURE__ */ globalThis.window.trustedTypes.createPolicy("svelte-trusted-html", { createHTML: (e) => e });
function rr(e) {
	return nr?.createHTML(e) ?? e;
}
function ir(e) {
	var t = Zt("template");
	return t.innerHTML = rr(e.replaceAll("<!>", "<!---->")), t.content;
}
//#endregion
//#region node_modules/svelte/src/internal/client/dom/template.js
function ar(e, t) {
	var n = q;
	n.nodes === null && (n.nodes = {
		start: e,
		end: t,
		a: null,
		t: null
	});
}
/*#__NO_SIDE_EFFECTS__*/
function or(e, t) {
	var n = !!(t & 1), r = !!(t & 2), i, a = !e.startsWith("<!>");
	return () => {
		if (T) return ar(E, null), E;
		i === void 0 && (i = ir(a ? e : "<!>" + e), n || (i = /* @__PURE__ */ Gt(i)));
		var t = r || Vt ? document.importNode(i, !0) : i.cloneNode(!0);
		if (n) {
			var o = /* @__PURE__ */ Gt(t), s = t.lastChild;
			ar(o, s);
		} else ar(t, t);
		return t;
	};
}
function sr(e, t) {
	if (T) {
		var n = q;
		(!(n.f & 32768) || n.nodes.end === null) && (n.nodes.end = E), Se();
		return;
	}
	e !== null && e.before(t);
}
//#endregion
//#region node_modules/svelte/src/reactivity/create-subscriber.js
function cr(e) {
	let t = 0, n = Nt(0), r;
	return () => {
		rn() && ($(n), un(() => (t === 0 && (r = Un(() => e(() => Lt(n)))), t += 1, () => {
			A(() => {
				--t, t === 0 && (r?.(), r = void 0, Lt(n));
			});
		})));
	};
}
//#endregion
//#region node_modules/svelte/src/internal/client/dom/blocks/boundary.js
var lr = x | S;
function ur(e, t, n, r) {
	new dr(e, t, n, r);
}
var dr = class {
	parent;
	is_pending = !1;
	transform_error;
	#e;
	#t = T ? E : null;
	#n;
	#r;
	#i;
	#a = null;
	#o = null;
	#s = null;
	#c = null;
	#l = 0;
	#u = 0;
	#d = !1;
	#f = /* @__PURE__ */ new Set();
	#p = /* @__PURE__ */ new Set();
	#m = null;
	#h = cr(() => (this.#m = Nt(this.#l), () => {
		this.#m = null;
	}));
	constructor(e, t, n, r) {
		this.#e = e, this.#n = t, this.#r = (e) => {
			var t = q;
			t.b = this, t.f |= 128, n(e);
		}, this.parent = q.b, this.transform_error = r ?? this.parent?.transform_error ?? ((e) => e), this.#i = fn(() => {
			if (T) {
				let e = this.#t;
				Se();
				let t = e.data === "[!";
				if (e.data.startsWith("[?")) {
					let t = JSON.parse(e.data.slice(2));
					this.#_(t);
				} else t ? this.#y() : this.#g();
			} else this.#b();
		}, lr), T && (this.#e = E);
	}
	#g() {
		try {
			this.#a = H(() => this.#r(this.#e));
		} catch (e) {
			this.error(e);
		}
	}
	#_(e) {
		let t = this.#n.failed, { reset: n, invoke_onerror: r } = this.#v(e);
		A(r), t && (this.#s = H(() => {
			t(this.#e, () => e, () => n);
		}));
	}
	#v(e) {
		var t = !1, n = !1;
		let r = () => {
			if (t) {
				be();
				return;
			}
			t = !0, n && ze(), this.#s !== null && vn(this.#s, () => {
				this.#s = null;
			}), this.#S(() => {
				this.#b();
			});
		};
		return {
			reset: r,
			invoke_onerror: () => {
				try {
					n = !0, this.#n.onerror?.(e, r), n = !1;
				} catch (e) {
					V(e, this.#i && this.#i.parent);
				}
			}
		};
	}
	#y() {
		let e = this.#n.pending;
		e && (this.is_pending = !0, this.#o = H(() => e(this.#e)), A(() => {
			var e = this.#c = document.createDocumentFragment(), t = R(), n = !1;
			if (e.append(t), this.#a = this.#S(() => {
				try {
					return H(() => this.#r(t));
				} catch (e) {
					try {
						this.error(e), n = !0;
					} catch (e) {
						V(e, this.#i.parent);
					}
					return null;
				}
			}), this.#a === null) {
				this.#c = null, n && this.#x(M);
				return;
			}
			this.#u === 0 && (this.#e.before(e), this.#c = null, vn(this.#o, () => {
				this.#o = null;
			}), this.#x(M));
		}));
	}
	#b() {
		try {
			if (this.is_pending = this.has_pending_snippet(), this.#u = 0, this.#l = 0, this.#a = H(() => {
				this.#r(this.#e);
			}), this.#u > 0) {
				var e = this.#c = document.createDocumentFragment();
				Sn(this.#a, e);
				let t = this.#n.pending;
				this.#o = H(() => t(this.#e));
			} else this.#x(M);
		} catch (e) {
			this.error(e);
		}
	}
	#x(e) {
		this.is_pending = !1, e.transfer_effects(this.#f, this.#p);
	}
	defer_effect(e) {
		Xe(e, this.#f, this.#p);
	}
	is_rendered() {
		return !this.is_pending && (!this.parent || this.parent.is_rendered());
	}
	has_pending_snippet() {
		return !!this.#n.pending;
	}
	#S(e) {
		var t = q, n = W, r = k;
		J(this.#i), K(this.#i), Be(this.#i.ctx);
		try {
			return Tt.ensure(), e();
		} finally {
			J(t), K(n), Be(r);
		}
	}
	#C(e, t) {
		if (!this.has_pending_snippet()) {
			this.parent && this.parent.#C(e, t);
			return;
		}
		this.#u += e, this.#u === 0 && (this.#x(t), this.#o && vn(this.#o, () => {
			this.#o = null;
		}), this.#c &&= (this.#e.before(this.#c), null));
	}
	update_pending_count(e, t) {
		this.#C(e, t), this.#l += e, !(!this.#m || this.#d) && (this.#d = !0, A(() => {
			this.#d = !1, this.#m && Ft(this.#m, this.#l);
		}));
	}
	get_effect_pending() {
		return this.#h(), $(this.#m);
	}
	error(e) {
		if (!this.#n.onerror && !this.#n.failed) throw e;
		M?.is_fork ? (this.#a && M.skip_effect(this.#a), this.#o && M.skip_effect(this.#o), this.#s && M.skip_effect(this.#s), M.oncommit(() => {
			this.#w(e);
		})) : this.#w(e);
	}
	#w(e) {
		this.#a &&= (U(this.#a), null), this.#o &&= (U(this.#o), null), this.#s &&= (U(this.#s), null), T && (D(this.#t), Ce(), D(we()));
		let t = this.#n.failed, n = (e) => {
			let { reset: n, invoke_onerror: r } = this.#v(e);
			r(), t && (this.#s = this.#S(() => {
				try {
					return H(() => {
						var r = q;
						r.b = this, r.f |= 128, t(this.#e, () => e, () => n);
					});
				} catch (e) {
					return V(e, this.#i.parent), null;
				}
			}));
		};
		A(() => {
			var t;
			try {
				t = this.transform_error(e);
			} catch (e) {
				V(e, this.#i && this.#i.parent);
				return;
			}
			typeof t == "object" && t && typeof t.then == "function" ? t.then(n, (e) => V(e, this.#i && this.#i.parent)) : n(t);
		});
	}
};
function fr(e, t) {
	var n = t == null ? "" : typeof t == "object" ? `${t}` : t;
	n !== (e[fe] ??= e.nodeValue) && (e[fe] = n, e.nodeValue = `${n}`);
}
function pr(e, t) {
	return hr(e, t);
}
var mr = /* @__PURE__ */ new Map();
function hr(e, { target: t, anchor: n, props: i = {}, events: a, context: o, intro: s = !0, transformError: c }) {
	Wt();
	var l = void 0, u = cn(() => {
		var s = n ?? t.appendChild(R());
		ur(s, { pending: () => {} }, (t) => {
			Ve({});
			var n = k;
			if (o && (n.c = o), a && (i.$$events = a), T && ar(t, null), l = e(t, i) || Ue(), T && (q.nodes.end = E, E === null || E.nodeType !== 8 || E.data !== "]")) throw ye(), ge;
			He();
		}, c);
		var u = /* @__PURE__ */ new Set(), d = (e) => {
			for (var n = 0; n < e.length; n++) {
				var r = e[n];
				if (!u.has(r)) {
					u.add(r);
					var i = Gn(r);
					for (let e of [t, document]) {
						var a = mr.get(e);
						a === void 0 && (a = /* @__PURE__ */ new Map(), mr.set(e, a));
						var o = a.get(r);
						o === void 0 ? (e.addEventListener(r, tr, { passive: i }), a.set(r, 1)) : a.set(r, o + 1);
					}
				}
			}
		};
		return d(r(qn)), Jn.add(d), () => {
			for (var e of u) for (let n of [t, document]) {
				var r = mr.get(n), i = r.get(e);
				--i == 0 ? (n.removeEventListener(e, tr), r.delete(e), r.size === 0 && mr.delete(n)) : r.set(e, i);
			}
			Jn.delete(d), s !== n && s.parentNode?.removeChild(s);
		};
	});
	return gr.set(l, u), l;
}
var gr = /* @__PURE__ */ new WeakMap(), _r = class {
	anchor;
	#e = /* @__PURE__ */ new Map();
	#t = /* @__PURE__ */ new Map();
	#n = /* @__PURE__ */ new Map();
	#r = /* @__PURE__ */ new Set();
	#i = !0;
	constructor(e, t = !0) {
		this.anchor = e, this.#i = t;
	}
	#a = (e) => {
		if (this.#e.has(e)) {
			var t = this.#e.get(e), n = this.#t.get(t);
			if (n) bn(n), this.#r.delete(t);
			else {
				var r = this.#n.get(t);
				r && (bn(r.effect), this.#t.set(t, r.effect), this.#n.delete(t), r.fragment.lastChild.remove(), this.anchor.before(r.fragment), n = r.effect);
			}
			for (let [t, n] of this.#e) {
				if (this.#e.delete(t), t === e) break;
				let r = this.#n.get(n);
				r && (U(r.effect), this.#n.delete(n));
			}
			for (let [e, r] of this.#t) {
				if (e === t || this.#r.has(e)) continue;
				let i = () => {
					if (Array.from(this.#e.values()).includes(e)) {
						var t = document.createDocumentFragment();
						Sn(r, t), t.append(R()), this.#n.set(e, {
							effect: r,
							fragment: t
						});
					} else U(r);
					this.#r.delete(e), this.#t.delete(e);
				};
				this.#i || !n ? (this.#r.add(e), vn(r, i, !1)) : i();
			}
		}
	};
	#o = (e) => {
		this.#e.delete(e);
		let t = Array.from(this.#e.values());
		for (let [e, n] of this.#n) t.includes(e) || (U(n.effect), this.#n.delete(e));
	};
	ensure(e, t) {
		var n = M, r = Xt();
		if (t && !this.#t.has(e) && !this.#n.has(e)) {
			if (r) {
				var i = document.createDocumentFragment(), a = R();
				i.append(a), this.#n.set(e, {
					effect: H(() => t(a)),
					fragment: i
				});
			} else this.#t.set(e, H(() => t(this.anchor)));
		}
		if (this.#e.set(n, e), r) {
			for (let [t, r] of this.#t) t === e ? n.unskip_effect(r) : n.skip_effect(r);
			for (let [t, r] of this.#n) t === e ? n.unskip_effect(r.effect) : n.skip_effect(r.effect);
			n.oncommit(this.#a), n.ondiscard(this.#o);
		} else T && (this.anchor = E), this.#a(n);
	}
};
//#endregion
//#region node_modules/svelte/src/internal/client/dom/blocks/if.js
function vr(e, t, n = !1) {
	var r;
	T && (r = E, Se());
	var i = new _r(e), a = n ? x : 0;
	function o(e, t) {
		if (T) {
			var n = Te(r);
			if (e !== parseInt(n.substring(1))) {
				var a = we();
				D(a), i.anchor = a, xe(!1), i.ensure(e, t), xe(!0);
				return;
			}
		}
		i.ensure(e, t);
	}
	fn(() => {
		var e = !1;
		t((t, n = 0) => {
			e = !0, o(n, t);
		}), e || o(-1, null);
	}, a);
}
//#endregion
//#region node_modules/svelte/src/internal/client/dom/blocks/each.js
function yr(e, t, n) {
	for (var i = [], a = t.length, o, s = t.length, c = 0; c < a; c++) {
		let n = t[c];
		vn(n, () => {
			if (o) {
				if (o.pending.delete(n), o.done.add(n), o.pending.size === 0) {
					var t = e.outrogroups;
					br(e, r(o.done)), t.delete(o), t.size === 0 && (e.outrogroups = null);
				}
			} else --s;
		}, !1);
	}
	if (s === 0) {
		var l = i.length === 0 && n !== null && e.pending.size === 0;
		if (l) {
			var u = n, d = u.parentNode;
			Yt(d), d.append(u), e.items.clear();
		}
		br(e, t, !l);
	} else o = {
		pending: new Set(t),
		done: /* @__PURE__ */ new Set()
	}, (e.outrogroups ??= /* @__PURE__ */ new Set()).add(o);
}
function br(e, t, n = !0) {
	var r;
	if (e.pending.size > 0) {
		r = /* @__PURE__ */ new Set();
		for (let t of e.pending.values()) for (let n of t) r.add(e.items.get(n).e);
	}
	for (var i = 0; i < t.length; i++) {
		var a = t[i];
		r?.has(a) ? (a.f |= te, Sn(a, document.createDocumentFragment())) : U(t[i], n);
	}
}
var xr;
function Sr(t, n, i, a, o, s = null) {
	var c = t, l = /* @__PURE__ */ new Map();
	if (n & 4) {
		var u = t;
		c = T ? D(/* @__PURE__ */ Gt(u)) : u.appendChild(R());
	}
	T && Se();
	var d = null, f = /* @__PURE__ */ ut(() => {
		var t = i();
		return e(t) ? t : t == null ? [] : r(t);
	}), p, m = /* @__PURE__ */ new Map(), h = !0;
	function g(e) {
		v.effect.f & 16384 || (v.pending.delete(e), v.fallback = d, wr(v, p, c, n, a), d !== null && (p.length === 0 ? d.f & 33554432 ? (d.f ^= te, Er(d, null, c)) : bn(d) : vn(d, () => {
			d = null;
		})));
	}
	function _(e) {
		v.pending.delete(e);
	}
	var v = {
		effect: fn(() => {
			p = $(f);
			var e = p.length;
			let t = !1;
			T && Te(c) === "[!" != (e === 0) && (c = we(), D(c), xe(!1), t = !0);
			for (var r = /* @__PURE__ */ new Set(), u = M, v = Xt(), y = 0; y < e; y += 1) {
				T && E.nodeType === 8 && E.data === "]" && (c = E, t = !0, xe(!1));
				var b = p[y], x = a(b, y), S = h ? null : l.get(x);
				S ? (S.v && Ft(S.v, b), S.i && Ft(S.i, y), v && u.unskip_effect(S.e)) : (S = Tr(l, h ? c : xr ??= R(), b, x, y, o, n, i), h || (S.e.f |= te), l.set(x, S)), r.add(x);
			}
			if (e === 0 && s && !d && (h ? d = H(() => s(c)) : (d = H(() => s(xr ??= R())), d.f |= te)), e > r.size && Ae("", "", ""), T && e > 0 && D(we()), !h) {
				if (m.set(u, r), v) {
					for (let [e, t] of l) r.has(e) || u.skip_effect(t.e);
					u.oncommit(g), u.ondiscard(_);
				} else g(u);
			}
			t && xe(!0), $(f);
		}),
		flags: n,
		items: l,
		pending: m,
		outrogroups: null,
		fallback: d
	};
	h = !1, T && (c = E);
}
function Cr(e) {
	for (; e !== null && !(e.f & 32);) e = e.next;
	return e;
}
function wr(e, t, n, i, a) {
	var o = !!(i & 8), s = t.length, c = e.items, l = Cr(e.effect.first), u, d = null, f, p = [], m = [], h, g, _, v;
	if (o) for (v = 0; v < s; v += 1) h = t[v], g = a(h, v), _ = c.get(g).e, _.f & 33554432 || (_.nodes?.a?.measure(), (f ??= /* @__PURE__ */ new Set()).add(_));
	for (v = 0; v < s; v += 1) {
		if (h = t[v], g = a(h, v), _ = c.get(g).e, e.outrogroups !== null) for (let t of e.outrogroups) t.pending.delete(_), t.done.delete(_);
		if (_.f & 8192 && (bn(_), o && (_.nodes?.a?.unfix(), (f ??= /* @__PURE__ */ new Set()).delete(_))), _.f & 33554432) {
			if (_.f ^= te, _ === l) Er(_, null, n);
			else {
				var y = d ? d.next : l;
				_ === e.effect.last && (e.effect.last = _.prev), _.prev && (_.prev.next = _.next), _.next && (_.next.prev = _.prev), Dr(e, d, _), Dr(e, _, y), Er(_, y, n), d = _, p = [], m = [], l = Cr(d.next);
				continue;
			}
		}
		if (_ !== l) {
			if (u !== void 0 && u.has(_)) {
				if (p.length < m.length) {
					var b = m[0], x;
					d = b.prev;
					var S = p[0], ee = p[p.length - 1];
					for (x = 0; x < p.length; x += 1) Er(p[x], b, n);
					for (x = 0; x < m.length; x += 1) u.delete(m[x]);
					Dr(e, S.prev, ee.next), Dr(e, d, S), Dr(e, ee, b), l = b, d = ee, --v, p = [], m = [];
				} else u.delete(_), Er(_, l, n), Dr(e, _.prev, _.next), Dr(e, _, d === null ? e.effect.first : d.next), Dr(e, d, _), d = _;
				continue;
			}
			for (p = [], m = []; l !== null && l !== _;) (u ??= /* @__PURE__ */ new Set()).add(l), m.push(l), l = Cr(l.next);
			if (l === null) continue;
		}
		_.f & 33554432 || p.push(_), d = _, l = Cr(_.next);
	}
	if (e.outrogroups !== null) {
		for (let t of e.outrogroups) t.pending.size === 0 && (br(e, r(t.done)), e.outrogroups?.delete(t));
		e.outrogroups.size === 0 && (e.outrogroups = null);
	}
	if (l !== null || u !== void 0) {
		var C = [];
		if (u !== void 0) for (_ of u) _.f & 8192 || C.push(_);
		for (; l !== null;) !(l.f & 8192) && l !== e.fallback && C.push(l), l = Cr(l.next);
		var ne = C.length;
		if (ne > 0) {
			var re = i & 4 && s === 0 ? n : null;
			if (o) {
				for (v = 0; v < ne; v += 1) C[v].nodes?.a?.measure();
				for (v = 0; v < ne; v += 1) C[v].nodes?.a?.fix();
			}
			yr(e, C, re);
		}
	}
	o && A(() => {
		if (f !== void 0) for (_ of f) _.nodes?.a?.apply();
	});
}
function Tr(e, t, n, r, i, a, o, s) {
	var c = o & 1 ? o & 16 ? Nt(n) : /* @__PURE__ */ Pt(n, !1, !1) : null, l = o & 2 ? Nt(i) : null;
	return {
		v: c,
		i: l,
		e: H(() => (a(t, c ?? n, l ?? i, s), () => {
			e.delete(r);
		}))
	};
}
function Er(e, t, n) {
	if (e.nodes) for (var r = e.nodes.start, i = e.nodes.end, a = t && !(t.f & 33554432) ? t.nodes.start : n; r !== null;) {
		var o = /* @__PURE__ */ Kt(r);
		if (a.before(r), r === i) return;
		r = o;
	}
}
function Dr(e, t, n) {
	t === null ? e.effect.first = n : t.next = n, n === null ? e.effect.last = t : n.prev = t;
}
//#endregion
//#region node_modules/svelte/src/internal/shared/attributes.js
var Or = [..." 	\n\r\f\xA0\v﻿"];
function kr(e, t, n) {
	var r = e == null ? "" : "" + e;
	if (t && (r = r ? r + " " + t : t), n) {
		for (var i of Object.keys(n)) if (n[i]) r = r ? r + " " + i : i;
		else if (r.length) for (var a = i.length, o = 0; (o = r.indexOf(i, o)) >= 0;) {
			var s = o + a;
			(o === 0 || Or.includes(r[o - 1])) && (s === r.length || Or.includes(r[s])) ? r = (o === 0 ? "" : r.substring(0, o)) + r.substring(s + 1) : o = s;
		}
	}
	return r === "" ? null : r;
}
function Ar(e, t = !1) {
	var n = t ? " !important;" : ";", r = "";
	for (var i of Object.keys(e)) {
		var a = e[i];
		a != null && a !== "" && (r += " " + i + ": " + a + n);
	}
	return r;
}
function jr(e) {
	return e[0] !== "-" || e[1] !== "-" ? e.toLowerCase() : e;
}
function Mr(e, t) {
	if (t) {
		var n = "", r, i;
		if (Array.isArray(t) ? (r = t[0], i = t[1]) : r = t, e) {
			e = String(e).replaceAll(/\/\*.*?\*\//g, "").trim();
			var a = !1, o = 0, s = !1, c = [];
			r && c.push(...Object.keys(r).map(jr)), i && c.push(...Object.keys(i).map(jr));
			var l = 0, u = -1;
			let t = e.length;
			for (var d = 0; d < t; d++) {
				var f = e[d];
				if (s ? f === "/" && e[d - 1] === "*" && (s = !1) : a ? a === f && (a = !1) : f === "/" && e[d + 1] === "*" ? s = !0 : f === "\"" || f === "'" ? a = f : f === "(" ? o++ : f === ")" && o--, !s && a === !1 && o === 0) {
					if (f === ":" && u === -1) u = d;
					else if (f === ";" || d === t - 1) {
						if (u !== -1) {
							var p = jr(e.substring(l, u).trim());
							if (!c.includes(p)) {
								f !== ";" && d++;
								var m = e.substring(l, d).trim();
								n += " " + m + ";";
							}
						}
						l = d + 1, u = -1;
					}
				}
			}
		}
		return r && (n += Ar(r)), i && (n += Ar(i, !0)), n = n.trim(), n === "" ? null : n;
	}
	return e == null ? null : String(e);
}
//#endregion
//#region node_modules/svelte/src/internal/client/dom/elements/class.js
function Nr(e, t, n, r, i, a) {
	var o = e[ue];
	if (T || o !== n || o === void 0) {
		var s = kr(n, r, a);
		(!T || s !== e.getAttribute("class")) && (s == null ? e.removeAttribute("class") : t ? e.className = s : e.setAttribute("class", s)), e[ue] = n;
	} else if (a && i !== a) for (var c in a) {
		var l = !!a[c];
		(i == null || l !== !!i[c]) && e.classList.toggle(c, l);
	}
	return a;
}
//#endregion
//#region node_modules/svelte/src/internal/client/dom/elements/style.js
function Pr(e, t = {}, n, r) {
	for (var i in n) {
		var a = n[i];
		t[i] !== a && (n[i] == null ? e.style.removeProperty(i) : e.style.setProperty(i, a, r));
	}
}
function Fr(e, t, n, r) {
	var i = e[de];
	if (T || i !== t) {
		var a = Mr(t, r);
		(!T || a !== e.getAttribute("style")) && (a == null ? e.removeAttribute("style") : e.style.cssText = a), e[de] = t;
	} else r && (Array.isArray(r) ? (Pr(e, n?.[0], r[0]), Pr(e, n?.[1], r[1], "important")) : Pr(e, n, r));
	return r;
}
//#endregion
//#region node_modules/svelte/src/internal/client/dom/elements/attributes.js
var Ir = Symbol("is custom element"), Lr = Symbol("is html"), Rr = he ? "link" : "LINK", zr = he ? "progress" : "PROGRESS";
function Br(e) {
	if (T) {
		var t = !1, n = () => {
			if (!t) {
				if (t = !0, e.hasAttribute("value")) {
					var n = e.value;
					Hr(e, "value", null), e.value = n;
				}
				if (e.hasAttribute("checked")) {
					var r = e.checked;
					Hr(e, "checked", null), e.checked = r;
				}
			}
		};
		e[pe] = n, A(n), et();
	}
}
function Vr(e, t) {
	var n = Ur(e);
	n.value !== (n.value = t ?? void 0) && (e.value !== t || t === 0 && e.nodeName === zr) && (e.value = t ?? "");
}
function Hr(e, t, n, r) {
	var i = Ur(e);
	T && (i[t] = e.getAttribute(t), t === "src" || t === "srcset" || t === "href" && e.nodeName === Rr) || i[t] !== (i[t] = n) && (t === "loading" && (e[ce] = n), n == null ? e.removeAttribute(t) : typeof n != "string" && Gr(e).has(t) ? e[t] = n : e.setAttribute(t, n));
}
function Ur(e) {
	return e[le] ??= {
		[Ir]: e.nodeName.includes("-"),
		[Lr]: e.namespaceURI === _e
	};
}
var Wr = /* @__PURE__ */ new Map();
function Gr(e) {
	var t = e.getAttribute("is") || e.nodeName, n = Wr.get(t);
	if (n) return n;
	Wr.set(t, n = /* @__PURE__ */ new Set());
	for (var r, i = e, a = Element.prototype; a !== i;) {
		for (var s in r = o(i), r) r[s].set && s !== "innerHTML" && s !== "textContent" && s !== "innerText" && n.add(s);
		i = l(i);
	}
	return n;
}
//#endregion
//#region node_modules/svelte/src/internal/client/reactivity/props.js
function Kr(e, t, n, r) {
	var i = !0, o = !!(n & 8), s = !!(n & 16), c = r, l = !0, u = void 0, d = () => s && i ? (u ??= /* @__PURE__ */ ot(r), $(u)) : (l && (l = !1, c = s ? Un(r) : r), c);
	let f;
	if (o) {
		var p = ae in e || se in e;
		f = a(e, t)?.set ?? (p && t in e ? (n) => e[t] = n : void 0);
	}
	var m, h = !1;
	o ? [m, h] = Qe(() => e[t]) : m = e[t], m === void 0 && r !== void 0 && (m = d(), f && (i && Fe(t), f(m)));
	var g = i ? () => {
		var n = e[t];
		return n === void 0 ? d() : (l = !0, n);
	} : () => {
		var n = e[t];
		return n !== void 0 && (c = void 0), n === void 0 ? c : n;
	};
	if (i && !(n & 4)) return g;
	if (f) {
		var _ = e.$$legacy;
		return (function(e, t) {
			return arguments.length > 0 ? ((!i || !t || _ || h) && f(t ? g() : e), e) : g();
		});
	}
	var v = !1, y = (n & 1 ? ot : ut)(() => (v = !1, g()));
	o && $(y);
	var b = q;
	return (function(e, t) {
		if (arguments.length > 0) {
			let n = t ? $(y) : i && o ? zt(e) : e;
			return L(y, n), v = !0, c !== void 0 && (c = n), e;
		}
		return Tn && v || b.f & 16384 ? y.v : $(y);
	});
}
//#endregion
//#region node_modules/svelte/src/internal/disclose-version.js
typeof window < "u" && ((window.__svelte ??= {}).v ??= /* @__PURE__ */ new Set()).add("5");
//#endregion
//#region src/ColorPicker.svelte
var qr = /* @__PURE__ */ or("<section class=\"picker svelte-enrzk4\"><div class=\"heading svelte-enrzk4\"><strong class=\"svelte-enrzk4\"> </strong><span class=\"svelte-enrzk4\"> </span></div> <div class=\"square svelte-enrzk4\" role=\"slider\" aria-valuemin=\"0\" aria-valuemax=\"100\" tabindex=\"0\"><i class=\"svelte-enrzk4\"></i></div> <input class=\"hue svelte-enrzk4\" type=\"range\" min=\"0\" max=\"359\"/> <div class=\"value-row svelte-enrzk4\"><span class=\"swatch svelte-enrzk4\"></span> <span>#</span> <input class=\"hex svelte-enrzk4\" maxlength=\"6\"/></div></section>");
function Jr(e, t) {
	Ve(t, !0);
	let n = Kr(t, "value", 15, "#f54927"), r = /* @__PURE__ */ I(8), i = /* @__PURE__ */ I(84), a = /* @__PURE__ */ I(96), o = /* @__PURE__ */ I(!1), s = /* @__PURE__ */ lt(() => `hsl(${$(r)} 100% 50%)`);
	function c(e) {
		let t = Number.parseInt(e.slice(1), 16), n = (t >> 16 & 255) / 255, r = (t >> 8 & 255) / 255, i = (t & 255) / 255, a = Math.max(n, r, i), o = a - Math.min(n, r, i), s = 0;
		return o && (s = a === n ? 60 * ((r - i) / o % 6) : a === r ? 60 * ((i - n) / o + 2) : 60 * ((n - r) / o + 4)), {
			h: s < 0 ? s + 360 : s,
			s: a ? o / a * 100 : 0,
			v: a * 100
		};
	}
	function l(e, t, n) {
		t /= 100, n /= 100;
		let r = n * t, i = r * (1 - Math.abs(e / 60 % 2 - 1)), a = n - r, o = [
			0,
			0,
			0
		];
		return o = e < 60 ? [
			r,
			i,
			0
		] : e < 120 ? [
			i,
			r,
			0
		] : e < 180 ? [
			0,
			r,
			i
		] : e < 240 ? [
			0,
			i,
			r
		] : e < 300 ? [
			i,
			0,
			r
		] : [
			r,
			0,
			i
		], `#${o.map((e) => Math.round((e + a) * 255).toString(16).padStart(2, "0")).join("")}`;
	}
	function u() {
		if (!/^#[0-9a-f]{6}$/i.test(n())) return;
		let e = c(n());
		L(r, e.h, !0), L(i, e.s, !0), L(a, e.v, !0);
	}
	function d() {
		n(l($(r), $(i), $(a)));
	}
	function f(e) {
		let t = e.currentTarget.getBoundingClientRect();
		L(i, Math.max(0, Math.min(100, (e.clientX - t.left) / t.width * 100)), !0), L(a, Math.max(0, Math.min(100, (1 - (e.clientY - t.top) / t.height) * 100)), !0), d();
	}
	function p(e) {
		L(o, !0), e.currentTarget.setPointerCapture(e.pointerId), f(e);
	}
	function m(e) {
		$(o) && f(e);
	}
	function h(e) {
		L(r, Number(e.currentTarget.value), !0), d();
	}
	on(() => {
		u();
	});
	var g = qr(), _ = z(g), v = z(_), y = Jt(v, !0), b = Jt(B(v), !0);
	O(_);
	var x = B(_, 2);
	let S;
	var ee = z(x);
	let te;
	O(x);
	var C = B(x, 2);
	Br(C);
	var ne = B(C, 2), re = z(ne);
	let ie;
	var ae = B(re, 4);
	Br(ae), O(ne), O(g), dn((e, o) => {
		fr(y, t.label), fr(b, t.description), Hr(x, "aria-label", t.label), Hr(x, "aria-valuenow", e), Hr(x, "aria-valuetext", n()), S = Fr(x, "", S, { "--hue": $(s) }), te = Fr(ee, "", te, {
			left: `${$(i)}%`,
			top: `${100 - $(a)}%`
		}), Vr(C, $(r)), Hr(C, "aria-label", `Hue ${t.label}`), ie = Fr(re, "", ie, { background: n() }), Vr(ae, o), Hr(ae, "aria-label", `Kode HEX ${t.label}`);
	}, [() => Math.round($(a)), () => n().slice(1).toUpperCase()]), Zn("pointerdown", x, p), Zn("pointermove", x, m), Zn("pointerup", x, () => L(o, !1)), Xn("pointercancel", x, () => L(o, !1)), Zn("input", C, h), Zn("input", ae, (e) => {
		let t = e.currentTarget.value.replace(/[^0-9a-f]/gi, "").slice(0, 6);
		e.currentTarget.value = t.toUpperCase(), t.length === 6 && n(`#${t.toLowerCase()}`);
	}), sr(e, g), He();
}
Qn([
	"pointerdown",
	"pointermove",
	"pointerup",
	"input"
]);
//#endregion
//#region src/RoleplayBubbles.svelte
var Yr = /* @__PURE__ */ or("<div><span class=\"tag svelte-1qruoc4\"> </span> <span class=\"content svelte-1qruoc4\"> </span></div>"), Xr = /* @__PURE__ */ or("<div class=\"bubble-layer svelte-1qruoc4\" aria-hidden=\"true\"></div>");
function Zr(e, t) {
	Ve(t, !0);
	let n = /* @__PURE__ */ I(zt([]));
	function r(e) {
		e.data?.action === "updateRoleplayBubbles" && L(n, Array.isArray(e.data.data) ? e.data.data : [], !0);
	}
	on(() => (window.addEventListener("message", r), () => window.removeEventListener("message", r)));
	var i = Xr();
	Sr(i, 21, () => $(n), (e) => e.serverId, (e, t) => {
		var n = Yr();
		let r, i;
		var a = z(n), o = Jt(a, !0), s = Jt(B(a, 2), !0);
		O(n), dn((e) => {
			r = Nr(n, 1, "bubble svelte-1qruoc4", null, r, {
				me: $(t).type === "me",
				do: $(t).type === "do"
			}), i = Fr(n, "", i, {
				left: `${$(t).x * 100}vw`,
				top: `${$(t).y * 100}vh`,
				opacity: $(t).opacity,
				"--bubble-scale": $(t).scale
			}), fr(o, e), fr(s, $(t).text);
		}, [() => $(t).type.toUpperCase()]), sr(e, n);
	}), O(i), sr(e, i), He();
}
//#endregion
//#region src/JobSettings.svelte
var Qr = /* @__PURE__ */ or("<p class=\"error svelte-1gn3sq9\" role=\"alert\"> </p>"), $r = /* @__PURE__ */ or("<div class=\"overlay svelte-1gn3sq9\" role=\"presentation\"><div class=\"panel svelte-1gn3sq9\" role=\"dialog\" aria-modal=\"true\" aria-labelledby=\"job-settings-title\" tabindex=\"-1\"><header class=\"svelte-1gn3sq9\"><div class=\"eyebrow svelte-1gn3sq9\"><i class=\"svelte-1gn3sq9\"></i> JOB CHANNEL CONTROL</div> <button class=\"close svelte-1gn3sq9\" type=\"button\" aria-label=\"Tutup\">×</button> <h1 id=\"job-settings-title\" class=\"svelte-1gn3sq9\"> </h1> <p class=\"svelte-1gn3sq9\">Sesuaikan warna teks dan outline pesan job. Warna dasar background tetap dipertahankan.</p></header> <div class=\"preview-title svelte-1gn3sq9\">LIVE PREVIEW</div> <div class=\"preview svelte-1gn3sq9\"><div class=\"svelte-1gn3sq9\"><strong class=\"svelte-1gn3sq9\">Nama Karakter</strong><b class=\"svelte-1gn3sq9\"> </b><time class=\"svelte-1gn3sq9\">20:45</time></div> <p class=\"svelte-1gn3sq9\">Contoh pesan pengumuman dari job akan terlihat seperti ini.</p></div> <form><div class=\"pickers svelte-1gn3sq9\"><!> <!></div> <!> <footer class=\"svelte-1gn3sq9\"><span class=\"svelte-1gn3sq9\">ESC untuk menutup</span> <div class=\"svelte-1gn3sq9\"><button class=\"secondary svelte-1gn3sq9\" type=\"button\">Batal</button> <button class=\"primary svelte-1gn3sq9\" type=\"submit\"> </button></div></footer></form></div></div>"), ei = /* @__PURE__ */ or("<!> <!>", 1);
function ti(e, t) {
	Ve(t, !0);
	let n = window.GetParentResourceName, r = n ? n() : "xian_chat", i = /* @__PURE__ */ I(!1), a = /* @__PURE__ */ I(!1), o = /* @__PURE__ */ I(""), s = /* @__PURE__ */ I(zt({
		label: "JOB",
		textColor: "#60a5fa",
		outlineColor: "#60a5fa"
	}));
	async function c(e, t = {}) {
		return (await fetch(`https://${r}/${e}`, {
			method: "POST",
			headers: { "Content-Type": "application/json; charset=UTF-8" },
			body: JSON.stringify(t)
		})).json();
	}
	function l() {
		$(a) || (L(i, !1), L(o, ""), c("closeJobSettings").catch(() => void 0));
	}
	async function u(e) {
		if (e.preventDefault(), !$(a)) {
			L(a, !0), L(o, "");
			try {
				let e = await c("saveJobSettings", {
					textColor: $(s).textColor,
					outlineColor: $(s).outlineColor
				});
				e?.success ? L(i, !1) : L(o, e?.message || "Pengaturan gagal disimpan.", !0);
			} catch {
				L(o, "Tidak dapat menghubungi game client.");
			} finally {
				L(a, !1);
			}
		}
	}
	function d(e) {
		e.data?.action === "openJobSettings" ? (L(s, {
			...$(s),
			...e.data.data || {}
		}, !0), L(o, ""), L(a, !1), L(i, !0)) : e.data?.action === "closeJobSettings" && (L(i, !1), L(a, !1));
	}
	function f(e) {
		$(i) && e.key === "Escape" && (e.preventDefault(), l());
	}
	on(() => (window.addEventListener("message", d), window.addEventListener("keydown", f), () => {
		window.removeEventListener("message", d), window.removeEventListener("keydown", f);
	}));
	var p = ei(), m = qt(p);
	Zr(m, {});
	var h = B(m, 2), g = (e) => {
		var t = $r(), n = z(t), r = z(n), i = B(z(r), 2), c = Jt(B(i, 2));
		Ce(2), O(r);
		var d = B(r, 4);
		let f;
		var p = z(d), m = Jt(B(z(p)), !0);
		Ce(), O(p), Ce(2), O(d);
		var h = B(d, 2), g = z(h), _ = z(g);
		Jr(_, {
			label: "Warna teks job",
			description: "Nama, badge, isi pesan, dan aksen",
			get value() {
				return $(s).textColor;
			},
			set value(e) {
				$(s).textColor = e;
			}
		}), Jr(B(_, 2), {
			label: "Outline job",
			description: "Garis tepi dan glow kartu pesan",
			get value() {
				return $(s).outlineColor;
			},
			set value(e) {
				$(s).outlineColor = e;
			}
		}), O(g);
		var v = B(g, 2), y = (e) => {
			var t = Qr(), n = Jt(t, !0);
			dn(() => fr(n, $(o))), sr(e, t);
		};
		vr(v, (e) => {
			$(o) && e(y);
		});
		var b = B(v, 2), x = B(z(b), 2), S = z(x), ee = B(S, 2), te = Jt(ee, !0);
		O(x), O(b), O(h), O(n), O(t), dn(() => {
			fr(c, `Chat ${$(s).label ?? ""}`), f = Fr(d, "", f, {
				"--accent": $(s).textColor,
				"--outline": $(s).outlineColor
			}), fr(m, $(s).label), S.disabled = $(a), ee.disabled = $(a), fr(te, $(a) ? "Menyimpan..." : "Simpan perubahan");
		}), Zn("click", t, (e) => e.target === e.currentTarget && l()), Zn("click", i, l), Xn("submit", h, u), Zn("click", S, l), sr(e, t);
	};
	vr(h, (e) => {
		$(i) && e(g);
	}), sr(e, p), He();
}
Qn(["click"]);
//#endregion
//#region src/main.ts
var ni = document.querySelector("#job-settings-root");
if (!ni) throw Error("Missing #job-settings-root");
pr(ti, { target: ni });
//#endregion
