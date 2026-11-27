"""Smoke: the hostile runner image has its allowlisted tools."""


def test_pytest_runs() -> None:
    assert True


def test_httpx_importable() -> None:
    import httpx

    assert httpx.__version__
